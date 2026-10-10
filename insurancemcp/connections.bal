import ballerina/http;

configurable string insuranceServiceUrl = "http://localhost:8083";

final http:Client insuranceAgentClient = check new (insuranceServiceUrl);
