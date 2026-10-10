import ballerina/mcp;

// MCP server listener on port 8084
@mcp:StreamableHttpServiceConfig {
    info: {
        name: "Insurance MCP Server",
        version: "1.0.0"
    },
    sessionMode: mcp:STATELESS
}
service mcp:StreamableHttpService /mcp on new mcp:StreamableHttpListener(8084) {

    // ─── Customer Tools ───────────────────────────────────────────────────────

    # Get insurance policy details for a given username.
    # Returns policy number, type, coverage amount, premium, dates, and status.
    #
    # + username - The username of the policy holder
    # + return - Policy details or an error message string
    @mcp:Tool {
        description: "Get insurance policy details for a given username. Returns policy number, type, coverage amount, premium, dates, and status."
    }
    remote function getPolicy(string username) returns PolicyResponse|string|error {
        UsernameRequest usernameRequest = {username: username};
        PolicyResponse|ErrorResponse result = check insuranceCustomerClient->post(
            "/insurance/customer/policy", usernameRequest);
        if result is PolicyResponse {
            return result;
        }
        ErrorResponse errResponse = result;
        string errMessage = errResponse.message;
        return errMessage;
    }

    # Get all insurance claims submitted by a given username.
    # Returns a list of claims with claim ID, type, amount, description, submitted date, and status.
    #
    # + username - The username of the policy holder
    # + return - List of claims or an error message string
    @mcp:Tool {
        description: "Get all insurance claims submitted by a given username. Returns a list of claims with claim ID, type, amount, description, submitted date, and status."
    }
    remote function getClaims(string username) returns Claim[]|string|error {
        UsernameRequest usernameRequest = {username: username};
        Claim[]|ErrorResponse result = check insuranceCustomerClient->post(
            "/insurance/customer/claims", usernameRequest);
        if result is Claim[] {
            return result;
        }
        ErrorResponse errResponse = result;
        string errMessage = errResponse.message;
        return errMessage;
    }

    # Submit a new insurance claim for a user.
    # The policy must be ACTIVE. Valid claim types: Outpatient, Hospitalization, Emergency, Pharmacy, DME, Medical.
    #
    # + username - The username of the policy holder
    # + claimType - Type of claim (Outpatient, Hospitalization, Emergency, Pharmacy, DME, Medical)
    # + amount - Claim amount in USD
    # + description - Description of the medical service or expense
    # + return - Success message or an error message string
    @mcp:Tool {
        description: "Submit a new insurance claim for a user. The policy must be ACTIVE. Valid claim types: Outpatient, Hospitalization, Emergency, Pharmacy, DME, Medical."
    }
    remote function submitClaim(string username, string claimType,
            decimal amount, string description) returns string|error {
        ClaimSubmitRequest submitRequest = {
            username: username,
            claimType: claimType,
            amount: amount,
            description: description
        };
        SuccessResponse|ErrorResponse result = check insuranceCustomerClient->post(
            "/insurance/customer/claims/submit", submitRequest);
        if result is SuccessResponse {
            string successMessage = result.message;
            return successMessage;
        }
        ErrorResponse errResponse = result;
        string errMessage = errResponse.message;
        return errMessage;
    }

    // ─── Agent Tools ──────────────────────────────────────────────────────────

    # List all insurance policies in the system.
    # Returns full details of every policy including username, policy number, coverage, premium, dates, and status.
    # Intended for agent/admin use.
    #
    # + return - Array of all insurance policies
    @mcp:Tool {
        description: "List all insurance policies in the system. Returns full details of every policy including username, policy number, coverage, premium, dates, and status. Intended for agent/admin use."
    }
    remote function listAllPolicies() returns InsurancePolicy[]|error {
        InsurancePolicy[] policies = check insuranceAgentClient->get("/insurance/agent/policies");
        return policies;
    }

    # Update the status of an insurance policy by its policy number.
    # Valid statuses: ACTIVE, EXPIRED, SUSPENDED. Intended for agent/admin use.
    #
    # + policyNumber - The policy number to update (e.g. POL-HEALTH-001)
    # + status - New status to set: ACTIVE, EXPIRED, or SUSPENDED
    # + return - Success message or an error message string
    @mcp:Tool {
        description: "Update the status of an insurance policy by its policy number. Valid statuses: ACTIVE, EXPIRED, SUSPENDED. Intended for agent/admin use."
    }
    remote function updatePolicyStatus(string policyNumber, string status) returns string|error {
        PolicyUpdateRequest updateRequest = {policyNumber: policyNumber, status: status};
        SuccessResponse|ErrorResponse result = check insuranceAgentClient->post(
            "/insurance/agent/policy/update", updateRequest);
        if result is SuccessResponse {
            string successMessage = result.message;
            return successMessage;
        }
        ErrorResponse errResponse = result;
        string errMessage = errResponse.message;
        return errMessage;
    }

    # Get all insurance claims across every policyholder, any status.
    # Returns claim ID, username, type, amount, description, submitted date, and status for every claim, with PENDING claims listed first. Intended for agent/admin use.
    #
    # + return - Array of all claims, PENDING first
    @mcp:Tool {
        description: "Get all insurance claims across every policyholder, any status (PENDING, APPROVED, REJECTED). Returns claim ID, username, type, amount, description, submitted date, and status for every claim, with PENDING claims listed first. Intended for agent/admin use."
    }
    remote function getAllClaims() returns AgentClaim[]|error {
        AgentClaim[] allClaims = check insuranceAgentClient->get("/insurance/agent/claims");
        return allClaims;
    }

    # Update the status of an insurance claim by its claim ID.
    # Valid statuses: PENDING, APPROVED, REJECTED. Intended for agent/admin use.
    #
    # + claimId - The claim ID to update (e.g. CLM-001)
    # + status - New status to set: PENDING, APPROVED, or REJECTED
    # + return - Success message or an error message string
    @mcp:Tool {
        description: "Update the status of an insurance claim by its claim ID. Valid statuses: PENDING, APPROVED, REJECTED. Intended for agent/admin use."
    }
    remote function updateClaim(string claimId, string status) returns string|error {
        ClaimUpdateRequest updateRequest = {claimId: claimId, status: status};
        SuccessResponse|ErrorResponse result = check insuranceAgentClient->post(
            "/insurance/agent/claim/update", updateRequest);
        if result is SuccessResponse {
            string successMessage = result.message;
            return successMessage;
        }
        ErrorResponse errResponse = result;
        string errMessage = errResponse.message;
        return errMessage;
    }
}
