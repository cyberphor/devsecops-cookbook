from logging import info
from os import environ
from azure.functions import AuthLevel
from azure.functions import FunctionApp
from azure.functions import HttpRequest
from azure.functions import HttpResponse
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient

SUBSCRIPTION_ID = environ["SUBSCRIPTION_ID"]
RESOURCE_GROUP_NAME = environ["RESOURCE_GROUP_NAME"]
CONTAINER_GROUP_NAME = environ["CONTAINER_GROUP_NAME"]

app = FunctionApp()
ctrl = ContainerInstanceManagementClient(
    DefaultAzureCredential(), 
    SUBSCRIPTION_ID
)

@app.function_name(name="start")
@app.route(route="start", auth_level=AuthLevel.FUNCTION)
def start(req: HttpRequest) -> HttpResponse:
    ctrl.container_groups.begin_start(
        RESOURCE_GROUP_NAME,
        CONTAINER_GROUP_NAME,
    )
    response_body = f"Starting '{CONTAINER_GROUP_NAME}'"
    info(response_body)
    return HttpResponse(response_body, status_code=200)

@app.function_name(name="stop")
@app.route(route="stop", auth_level=AuthLevel.FUNCTION)
def stop(req: HttpRequest) -> HttpResponse:
    ctrl.container_groups.stop(
        RESOURCE_GROUP_NAME, CONTAINER_GROUP_NAME,
    )
    response_body = f"Stopping '{CONTAINER_GROUP_NAME}'"
    info(response_body)
    return HttpResponse(response_body, status_code=200)