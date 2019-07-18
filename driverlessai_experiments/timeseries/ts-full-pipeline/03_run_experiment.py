import click

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
    # print all the passed parameters
    import inspect
    _, _, _, values = inspect.getargvalues(inspect.currentframe())
    print(values)


if __name__ == '__main__':
    # Call the main processing function
    process()