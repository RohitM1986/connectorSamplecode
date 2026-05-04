# CRM F&O PoC - Generic Third-Party API Integration Package

**D365 F&O Environment**: `https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com/`

## Overview
This is an installable package for Microsoft Dynamics 365 Finance & Operations that:
- Pulls data from the Dynamics 365 Customer/Account table
- Sends data to **any generic third-party API** with flexible configuration
- Processes and stores the response
- Supports multiple authentication methods, HTTP methods, and custom headers

## Key Features

✅ **Multiple Authentication Methods**: API Key, Bearer Token, Basic Auth, or None  
✅ **Flexible HTTP Methods**: GET, POST, PUT, DELETE, PATCH  
✅ **Custom Headers Support**: Add any headers required by your API  
✅ **Dynamic Endpoints**: Override endpoint per request for multi-endpoint APIs  
✅ **Configurable Content Types**: JSON, XML, or custom formats  
✅ **Automatic Retry Logic**: Exponential backoff with configurable retries  
✅ **Comprehensive Logging**: Full audit trail of all API calls  

## Project Structure
```
CRMFOpoC/
├── Metadata/           # D365 F&O metadata files
│   ├── Classes/        # X++ class files
│   ├── DataContracts/  # Data contract classes
│   ├── MenuItems/      # Menu item definitions
│   └── Resources/      # Resource files
├── Descriptor/         # Package descriptor files
├── Scripts/            # Deployment and build scripts
└── README.md
```

## Components

### Core Classes
1. **CRMExternalAPIIntegration** - Main orchestration class
2. **CRMAccountDataService** - Data access layer for account table
3. **CRMExternalAPIService** - External API communication service
4. **CRMIntegrationBatch** - Batch job for scheduled execution

### Data Contracts
1. **CRMAccountDataContract** - Contract for account data
2. **CRMAPIRequestContract** - Contract for API requests
3. **CRMAPIResponseContract** - Contract for API responses

## Installation

### Prerequisites
- Microsoft Dynamics 365 Finance & Operations environment
- Developer access to D365 F&O
- Visual Studio with Dynamics 365 extension
- .NET Framework 4.7.2 or higher

### Deployment Steps
1. Clone this repository to your development environment
2. Open the project in Visual Studio
3. Build the solution (Build > Build Solution)
4. Deploy to D365 F&O environment using the deployment script
5. Synchronize the database
6. Configure the external API endpoint in parameters

### Using PowerShell Deployment Script
```powershell
.\Scripts\Deploy-Package.ps1 -Environment "https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com/" -PackagePath ".\Output"
```

## Configuration

### API Configuration
Update the following parameters in D365 F&O:
- Navigate to: **Organization administration > Setup > CRM Integration Parameters**
- Configure the following based on your third-party API:
  - **API Endpoint URL**: Your third-party API endpoint
  - **Authentication Type**: Choose from API Key, Bearer Token, Basic Auth, or None
  - **Authentication Credentials**: API Key, Bearer Token, or Basic Auth credentials
  - **HTTP Method**: GET, POST, PUT, DELETE, or PATCH (default: POST)
  - **Content Type**: application/json, application/xml, etc. (default: application/json)
  - **Timeout Settings**: Request timeout in seconds (default: 30)
  - **Retry Policy**: Maximum retry attempts (default: 3)
  - **Batch Size**: Records per batch (default: 100)

📖 **For detailed configuration and usage examples, see [THIRD_PARTY_API_GUIDE.md](THIRD_PARTY_API_GUIDE.md)**

### Batch Job Setup
1. Go to **System administration > Inquiries > Batch jobs**
2. Create a new batch job
3. Add task: **CRMIntegrationBatch**
4. Configure recurrence and execution window

## Usage

### Quick Start - Default Configuration
```xpp
// Initialize service (uses configuration from parameters)
CRMExternalAPIService apiService = new CRMExternalAPIService();

// Create and send request
CRMAPIRequestContract request = new CRMAPIRequestContract();
request.parmRequestType('DataSync');
// ... add your data

CRMAPIResponseContract response = apiService.sendData(request);

if (response.isSuccess())
{
    info(strFmt("Success! Processed %1 records", response.parmProcessedRecords()));
}
```

### Advanced Usage - Custom Endpoint and Headers
```xpp
CRMExternalAPIService apiService = new CRMExternalAPIService();

// Add custom headers
apiService.addCustomHeader('X-Correlation-Id', guid2Str(newGuid()));
apiService.addCustomHeader('X-Client-Id', 'D365-Client');

// Send to custom endpoint with PUT method
CRMAPIResponseContract response = apiService.sendData(
    request, 
    'https://api.example.com/v2/update',  // Custom endpoint
    'PUT'  // HTTP method
);
```

### Manual Execution
```xpp
CRMExternalAPIIntegration integration = new CRMExternalAPIIntegration();
integration.run();
```

### Batch Execution
Schedule the **CRMIntegrationBatch** class to run automatically.

## Development

### Building Custom Extensions
1. Extend the base classes using Chain of Command (CoC)
2. Add custom fields to data contracts
3. Implement custom business logic in event handlers

### Testing
Run unit tests from Visual Studio:
```
Test > Run > All Tests
```

## API Contract Examples

### Request Format
```json
{
    "accountNumber": "CUST-001",
    "accountName": "Contoso Ltd",
    "email": "contact@contoso.com",
    "phone": "+1-555-0123",
    "address": {
        "street": "123 Main St",
        "city": "Seattle",
        "state": "WA",
        "zipCode": "98101",
        "country": "USA"
    }
}
```

### Response Format
```json
{
    "status": "success",
    "transactionId": "TXN-12345",
    "validationResult": "approved",
    "timestamp": "2026-02-09T10:30:00Z"
}
```

## Error Handling
- All API calls include retry logic (3 attempts)
- Errors are logged to the D365 F&O event log
- Failed transactions are stored for manual review

## Security
- API keys are stored encrypted in D365 parameter tables
- HTTPS/TLS required for all API communications
- Role-based access control for execution

## Support
For issues or questions, contact your D365 administrator.

## Version History
- **1.0.0** - Initial release
  - Account data extraction
  - External API integration
  - Batch job support

## License
Proprietary - Internal use only
