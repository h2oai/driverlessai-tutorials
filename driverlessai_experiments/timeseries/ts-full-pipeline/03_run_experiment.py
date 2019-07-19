import click
import json
import os

import h2oai_client as h2o

@click.command()
@click.option('-h', '--host', 'dai_host',
              required=True,
              help='Driverless AI host url e.g http://hostname:12345')
@click.option('-u', '--user', 'dai_user',
              required=True,
              help='Driverless AI username')
@click.option('-p', '--pass', 'dai_pass',
              required=True,
              help='Driverless AI password')
@click.option('-d', '--train', 'train_ds', type=click.Path(exists=True,
                                                           file_okay=True,
                                                           dir_okay=False,
                                                           readable=True),
              required=True,
              help='Training dataset CSV file path.')
@click.option('-c', '--config', 'exp_config', type=click.Path(exists=True,
                                                              file_okay=True,
                                                              dir_okay=False,
                                                              readable=True),
              required=True,
              help='Default experiment config file.')
@click.option('-j', '--project', 'project_name',
              required=True,
              help='Project name to use for organizing the experiment. If does not exist, new project is created.')
@click.option('-t', '--test', 'test_ds', type=click.Path(exists=True,
                                                         file_okay=True,
                                                         dir_okay=False,
                                                         readable=True),
              required=False,
              default=None,
              help='Testing dataset CSV file path.')
def process(dai_host,
            dai_user,
            dai_pass,
            train_ds,
            exp_config,
            project_name,
            test_ds):
    """

    :param dai_host: Driverless AI host URL e.g. http://localhost:12345
    :param dai_user: Driverless AI user name
    :param dai_pass: Driverless AI password
    :param train_ds: path to training dataset csv file
    :param exp_config: path to experiment config json file
    :param project_name: Project name to organize datasets and experiments
    :param test_ds: path to testing dataset csv file (optional)
    :return: None
    """
    # print all the passed parameters
    # import inspect
    # _, _, _, values = inspect.getargvalues(inspect.currentframe())
    # print(values)

    # Create a connection to Driverless AI
    con = h2o.Client(address=dai_host,
                     username=dai_user,
                     password=dai_pass)

    # Get project key
    project_key = get_project_key(con, project_name)

    # Upload datasets and link to project
    test_ds_key = None
    train_ds_key = upload_dataset_to_project(con, project_key, train_ds, "Training")
    if test_ds is not None:
        test_ds_key = upload_dataset_to_project(con, project_key, test_ds, "Testing")

    # Read experiment config file and overwrite needed configs, save the config on file system
    with open(exp_config, 'r') as read_file:
        experiment_configs = json.load(read_file)
    experiment_configs['dataset_key'] = train_ds_key
    if test_ds_key is not None:
        experiment_configs['testset_key'] = test_ds_key
    with open('experiment-config.json', 'w') as write_file:
        json.dump(experiment_configs, write_file, indent=4)

    # Execute the experiment, link to project
    experiment: h2o.Model = con.start_experiment_sync(**experiment_configs)
    con.link_experiment_to_project(project_key,experiment.key)

    # build mojo pipeline
    mojo: h2o.MojoPipeline = con.build_mojo_pipeline_sync(experiment.key)

    # download mojo and python scoring pipelines and experiment summary
    con.download(experiment.scoring_pipeline_path, "")
    con.download(experiment.summary_path, "")
    con.download(mojo.file_path, "")

    # Finally save experiment.json
    with open('experiment.json', 'w') as write_file:
        json.dump(experiment.dump(), write_file, indent=4)



def upload_dataset_to_project(con: h2o.Client,
                              project_key: str,
                              dataset_file: str,
                              dataset_type: str):
    """
    Uploads the data provided in dataset_file path to Driverless AI and links to the project. If the project already
    has a dataset of the specified type and filename linked, then it is not re-uploaded. For the uploaded dataset, the
    dataset_key of the newly uploaded dataset is returned. If it is not uploaded, then key of the dataset matching the
    file name is returned.

    :param con: Connection to H2O Driverless AI
    :param project_key: Key of the project to link the dataset to
    :param dataset_file: File path of the dataset to upload and link to project
    :param dataset_type: Either 'Training' or 'Testing'
    :return: dataset_key
    """
    file_name = os.path.basename(dataset_file)
    datasets = con.get_datasets_for_project(project_key, dataset_type)
    dataset = next((x for x in datasets if x.name == file_name), None)
    if dataset is None:
        dataset = con.upload_dataset_sync(file_path=dataset_file)
        con.link_dataset_to_project(project_key=project_key,
                                    dataset_key=dataset.key,
                                    dataset_type=dataset_type)
    return dataset.key


def get_project_key(con: h2o.Client,
                    project_name: str) -> str:
    """
    Returns the key of the project with name matching project_name. If such a project does not exist, a new project is
    created and its key is returned.

    :param con: Client to H2O Driverless AI
    :param project_name: Name of the project
    :return:
    """
    projects = con.list_projects(offset=0, limit=1000)
    project = next((x for x in projects if x.name == project_name), None)
    if project is None:
        key = con.create_project(project_name, project_name)
        return key
    return project.key


if __name__ == '__main__':
    # Call the main processing function
    process()
