import ballerina/mcp;
import ballerina/time;

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
        InsurancePolicy? policy = policyDatabase[username];
        if policy is () {
            return "No policy found for username: " + username;
        }
        return {
            policyNumber: policy.policyNumber,
            policyType: policy.policyType,
            coverageAmount: policy.coverageAmount,
            premiumAmount: policy.premiumAmount,
            startDate: policy.startDate,
            endDate: policy.endDate,
            status: policy.status,
            organization: policy?.organization
        };
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
        InsurancePolicy? policy = policyDatabase[username];
        if policy is () {
            return "No policy found for username: " + username;
        }
        Claim[]? userClaims = claimsDatabase[username];
        if userClaims is () {
            return [];
        }
        return userClaims;
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
        InsurancePolicy? policy = policyDatabase[username];
        if policy is () {
            return "No policy found for username: " + username;
        }
        string policyStatus = policy.status;
        if policyStatus != "ACTIVE" {
            return "Cannot submit claim. Policy status is: " + policyStatus;
        }

        time:Utc currentTime = time:utcNow();
        string claimId = "CLM-" + currentTime[0].toString();

        Claim newClaim = {
            claimId: claimId,
            claimType: claimType,
            amount: amount,
            description: description,
            submittedDate: time:utcToString(currentTime).substring(0, 10),
            status: "PENDING"
        };

        Claim[]? existingClaims = claimsDatabase[username];
        if existingClaims is () {
            claimsDatabase[username] = [newClaim];
        } else {
            existingClaims.push(newClaim);
        }

        return "Claim " + claimId + " submitted successfully and is under review";
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
        return policyDatabase.toArray();
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
        foreach string username in policyDatabase.keys() {
            InsurancePolicy? policy = policyDatabase[username];
            if policy is InsurancePolicy && policy.policyNumber == policyNumber {
                policy.status = status;
                policyDatabase[username] = policy;
                return "Policy " + policyNumber + " updated to status: " + status;
            }
        }
        return "Policy not found: " + policyNumber;
    }

    # Get all insurance claims across every policyholder, any status.
    # Returns claim ID, username, type, amount, description, submitted date, and status for every claim, with PENDING claims listed first. Intended for agent/admin use.
    #
    # + return - Array of all claims, PENDING first
    @mcp:Tool {
        description: "Get all insurance claims across every policyholder, any status (PENDING, APPROVED, REJECTED). Returns claim ID, username, type, amount, description, submitted date, and status for every claim, with PENDING claims listed first. Intended for agent/admin use."
    }
    remote function getAllClaims() returns AgentClaim[]|error {
        AgentClaim[] pending = [];
        AgentClaim[] others = [];
        foreach string username in claimsDatabase.keys() {
            Claim[]? userClaims = claimsDatabase[username];
            if userClaims is Claim[] {
                foreach Claim c in userClaims {
                    AgentClaim agentClaim = {
                        username: username,
                        claimId: c.claimId,
                        claimType: c.claimType,
                        amount: c.amount,
                        description: c.description,
                        submittedDate: c.submittedDate,
                        status: c.status
                    };
                    if c.status == "PENDING" {
                        pending.push(agentClaim);
                    } else {
                        others.push(agentClaim);
                    }
                }
            }
        }
        foreach AgentClaim ac in others {
            pending.push(ac);
        }
        return pending;
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
