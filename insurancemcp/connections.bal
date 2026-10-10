import ballerina/http;

configurable string insuranceAgentServiceUrl = "http://localhost:8083";
configurable string insuranceCustomerServiceUrl = "http://localhost:8082";

final http:Client insuranceAgentClient = check new (insuranceAgentServiceUrl);
final http:Client insuranceCustomerClient = check new (insuranceCustomerServiceUrl);
