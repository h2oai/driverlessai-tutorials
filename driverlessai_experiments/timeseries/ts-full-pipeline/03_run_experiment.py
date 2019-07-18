import click
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

    project_key = get_project_key(con, project_name)
    print(project_key)



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
