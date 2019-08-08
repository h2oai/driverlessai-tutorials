from starlette.applications import Starlette
from starlette.responses import JSONResponse

import click
import base64
import importlib
import pickle
import json
import uvicorn

# Create a global scorer and assign to None for now
scorer = None

app = Starlette(debug=True)


@app.route("/predict", methods=['POST'])
async def predict(request):
    request_content = await request.body()
    request_content_json = json.loads(request_content)
    score_ds = pickle.loads(base64.b64decode(request_content_json['payload']))
    if scorer is not None and type(score_ds).__name__ == 'DataFrame':
        pred_ds = scorer.score_batch(score_ds)
        enc_preds = base64.b64encode(pickle.dumps(pred_ds)).decode()
        return JSONResponse(content={'payload': enc_preds},
                            status_code=200)
    else:
        return JSONResponse(content={'payload': 'Error scorer could not load or request payload not pandas DataFrame'},
                            status_code=500)


@click.command()
@click.option('-n', '--name', 'experiment_name',
              required=True,
              type=click.types.STRING,
              help='Experiment Name')
@click.option('-p', '--port', 'port',
              required=False,
              type=click.types.INT,
              default=9090)
def process(experiment_name,
            port):
    """
    Executes a HTTP prediction server for the Driverless AI python pipeline.
    Will create a '/predict' endpoint that will respond to only HTTP posts. Expected input for the endpoint
    is a pandas DataFrame for batch scoring using the 'score_batch' operation of the DAI python scoring pipeline.
    The pandas DataFrame should be pickled and then Base64 encoded and then sent in the Request body.

    :param experiment_name: Name of the Driverless AI experiment for which the scoring pipeline is used
    :param port: Port number to listen to for input data to predict
    :return:
    """
    # Make function aware about the global variable scorer, and then set it
    global scorer
    scorer = experiment_name
    scoring_module_name = 'scoring_h2oai_experiment_{}'.format(experiment_name)
    scoring_module = importlib.import_module(scoring_module_name)
    scoring_class = getattr(scoring_module, 'Scorer')
    scorer = scoring_class()

    # Refer to the list of supported kwargs
    # https://github.com/encode/uvicorn/blob/e95e995781c7d1d8661b4f94631e3adb77c85237/uvicorn/main.py#L196
    uvicorn.run(app,
                host='0.0.0.0',
                port=port)


if __name__ == "__main__":
    process()
