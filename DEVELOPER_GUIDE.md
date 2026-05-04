# Developer Guide - CRM F&O PoC Package

**D365 F&O Environment**: `https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com/`

## Development Environment Setup

### Prerequisites

1. **Visual Studio 2017 or later**
   - Dynamics 365 Unified Operations extension
   - .NET development workload
   - C# and X++ language support

2. **D365 F&O Development Environment**
   - Local VM or cloud-hosted development environment
   - Access to Application Object Tree (AOT)
   - SQL Server access

3. **Source Control**
   - Git configured
   - Access to repository

### Project Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd CRMFOpoC

# D365 F&O Environment: https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com/
```

2. Open in Visual Studio:
   - File > Open > Project/Solution
   - Navigate to the project folder
   - Open the `.sln` file

3. Restore dependencies:
   - Build > Restore NuGet Packages
   - Dynamics 365 > Update Model Parameters

## Project Structure

```
CRMFOpoC/
├── Metadata/
│   ├── Classes/              # X++ class files
│   │   ├── CRMAccountDataContract.xpp
│   │   ├── CRMAccountAddressContract.xpp
│   │   ├── CRMAPIRequestContract.xpp
│   │   ├── CRMAPIResponseContract.xpp
│   │   ├── CRMAccountDataService.xpp
│   │   ├── CRMExternalAPIService.xpp
│   │   ├── CRMExternalAPIIntegration.xpp
│   │   ├── CRMIntegrationBatch.xpp
│   │   ├── CRMIntegrationParameters.xpp
│   │   └── CRMIntegrationLog.xpp
│   ├── Tables/               # Table metadata
│   │   ├── CRMIntegrationParameters.xml
│   │   └── CRMIntegrationLog.xml
│   ├── MenuItems/            # Menu item definitions
│   │   ├── CRMExternalAPIIntegration.xml
│   │   ├── CRMIntegrationParameters.xml
│   │   └── CRMIntegrationLog.xml
│   └── Resources/            # Resource files
├── Descriptor/               # Package descriptor
│   └── CRMFOpoC.xml
├── Scripts/                  # PowerShell scripts
│   ├── Build-Package.ps1
│   ├── Deploy-Package.ps1
│   └── Test-Integration.ps1
├── README.md
├── INSTALLATION.md
├── API_INTEGRATION.md
└── DEVELOPER_GUIDE.md
```

## Key Components

### Data Contracts

Data contracts define the structure for API communication:

**CRMAccountDataContract**: Customer account data
```xpp
[DataContractAttribute]
public class CRMAccountDataContract
{
    private CustAccount accountNumber;
    private Name accountName;
    // ... other fields
    
    [DataMemberAttribute('AccountNumber')]
    public CustAccount parmAccountNumber(CustAccount _accountNumber = accountNumber)
    {
        accountNumber = _accountNumber;
        return accountNumber;
    }
}
```

### Service Classes

**CRMAccountDataService**: Data access layer
- Retrieves customer data from D365 tables
- Maps data to contracts
- Handles data transformation

**CRMExternalAPIService**: API communication
- Sends HTTP requests
- Handles authentication
- Manages retries and error handling

### Orchestration

**CRMExternalAPIIntegration**: Main controller
- Coordinates data flow
- Manages batch processing
- Provides user interface

## Development Guidelines

### Naming Conventions

1. **Classes**: PascalCase with CRM prefix
   - `CRMAccountDataService`
   - `CRMExternalAPIIntegration`

2. **Methods**: camelCase with descriptive names
   - `getAccounts()`
   - `sendAccountData()`

3. **Variables**: camelCase with underscore prefix for parameters
   - `_accountNumber`
   - `_fromDate`

4. **Constants**: UPPER_CASE
   - `DefaultBatchSize`
   - `ContentTypeJson`

### Code Standards

#### X++ Best Practices

1. **Use try-catch blocks**:
```xpp
try
{
    // Your code
}
catch (Exception::Error)
{
    error("Operation failed");
    throw;
}
```

2. **Validate inputs**:
```xpp
public boolean validate(Object _calledFrom = null)
{
    boolean ret = super(_calledFrom);
    
    if (batchSize <= 0)
    {
        ret = checkFailed("Batch size must be greater than 0");
    }
    
    return ret;
}
```

3. **Use transactions**:
```xpp
ttsbegin;
try
{
    // Database operations
    record.insert();
    ttscommit;
}
catch
{
    ttsabort;
    throw;
}
```

4. **Implement logging**:
```xpp
private void logAPICall(CRMAPIRequestContract _request, 
                       CRMAPIResponseContract _response)
{
    CRMIntegrationLog log;
    
    ttsbegin;
    log.RequestId = _request.parmRequestId();
    log.Status = _response.parmStatus();
    log.insert();
    ttscommit;
}
```

### Extension Points

To extend the functionality:

#### 1. Add Custom Fields to Contracts

```xpp
[DataContractAttribute]
public final class CRMAccountDataContract_Extension
{
    private str customField;
    
    [DataMemberAttribute('CustomField')]
    public str parmCustomField(str _customField = customField)
    {
        customField = _customField;
        return customField;
    }
}
```

#### 2. Chain of Command (CoC)

Extend existing methods without modifying source:

```xpp
[ExtensionOf(classStr(CRMAccountDataService))]
final class CRMAccountDataService_Extension
{
    public List getAccounts(TransDate _fromDate = dateNull(), 
                           TransDate _toDate = dateNull(),
                           CustGroupId _custGroup = '')
    {
        List accountList = next getAccounts(_fromDate, _toDate, _custGroup);
        
        // Add custom logic here
        
        return accountList;
    }
}
```

#### 3. Event Handlers

Subscribe to events:

```xpp
class CRMIntegrationEventHandlers
{
    [DataEventHandler(tableStr(CustTable), DataEventType::Inserted)]
    public static void CustTable_onInserted(Common _sender, DataEventArgs _e)
    {
        CustTable custTable = _sender as CustTable;
        
        // Trigger integration when new customer created
        // Add to queue or trigger immediate sync
    }
}
```

## Testing

### Unit Tests

Create unit tests in Visual Studio:

```xpp
[TestFixture]
class CRMAccountDataServiceTest extends SysTestCase
{
    [Test]
    public void testGetAccounts()
    {
        CRMAccountDataService service;
        List accountList;
        
        service = new CRMAccountDataService();
        accountList = service.getAccounts();
        
        this.assertNotNull(accountList, "Account list should not be null");
    }
    
    [Test]
    public void testGetAccountByNumber()
    {
        CRMAccountDataService service;
        CRMAccountDataContract account;
        
        service = new CRMAccountDataService();
        account = service.getAccountByNumber('US-001');
        
        this.assertNotNull(account, "Account should be found");
        this.assertEquals('US-001', account.parmAccountNumber(), 
            "Account number should match");
    }
}
```

### Integration Tests

Test the full flow:

```xpp
[TestFixture]
class CRMIntegrationTest extends SysTestCase
{
    [Test]
    public void testFullIntegration()
    {
        CRMExternalAPIIntegration integration;
        CRMExternalAPIService apiService;
        
        // Setup
        integration = new CRMExternalAPIIntegration();
        apiService = new CRMExternalAPIService();
        
        // Configure test endpoint
        apiService.setAPIEndpoint('https://test-api.example.com/v1/sync');
        apiService.setAPIKey('test-key');
        
        // Execute
        integration.parmBatchSize(10);
        integration.run();
        
        // Verify logs
        CRMIntegrationLog log = this.getLatestLog();
        this.assertNotNull(log, "Log should be created");
        this.assertEquals(NoYes::Yes, log.Success, "Integration should succeed");
    }
    
    private CRMIntegrationLog getLatestLog()
    {
        CRMIntegrationLog log;
        
        select firstonly log
            order by RequestTimestamp desc;
            
        return log;
    }
}
```

### Manual Testing

1. **Test in UI**:
   - Run the integration manually
   - Verify parameters dialog
   - Check infolog messages

2. **Test API Service**:
```xpp
static void TestAPIService(Args _args)
{
    CRMExternalAPIService apiService = new CRMExternalAPIService();
    boolean connected = apiService.testConnection();
    
    info(strFmt("Connection test: %1", connected ? "Success" : "Failed"));
}
```

## Debugging

### Enable Debug Mode

1. In Visual Studio:
   - Set breakpoints in X++ code
   - Debug > Attach to Process
   - Select w3wp.exe (IIS process)

2. In X++ code:
```xpp
// Add debug info
Info(strFmt("Debug: Processing account %1", accountNumber));

// Use BP() for breakpoint
BP();

// Check conditions
if (Debug::isDebuggerAttached())
{
    // Debug-only code
}
```

### Logging

Add detailed logging:

```xpp
private void logDebugInfo(str _message)
{
    if (isConfigurationMode())
    {
        info(strFmt("[DEBUG] %1", _message));
    }
}
```

### Common Issues

**Issue**: API timeout
```xpp
// Solution: Increase timeout in parameters
apiService.setTimeoutSeconds(60);
```

**Issue**: Serialization error
```xpp
// Solution: Ensure all contract fields have proper attributes
[DataContractAttribute]
[DataMemberAttribute('FieldName')]
```

**Issue**: Database lock
```xpp
// Solution: Use proper transaction scope
ttsbegin;
// Keep transaction scope small
ttscommit;
```

## Building and Deployment

### Build Process

1. **Local Build**:
```powershell
# Build in Visual Studio
Build > Build Solution

# Or use MSBuild
msbuild CRMFOpoC.sln /p:Configuration=Release
```

2. **Build Script**:
```powershell
.\Scripts\Build-Package.ps1 -Configuration Release -OutputPath .\Output
```

### Deployment Process

1. **Deploy to Development**:
   - Build in Visual Studio
   - Dynamics 365 > Deploy Model
   - Synchronize database

2. **Deploy to Test/Production**:
```powershell
.\Scripts\Deploy-Package.ps1 `
    -Environment "Production" `
    -PackagePath ".\Output" `
    -SyncDatabase
```

## Performance Optimization

### Database Queries

1. **Use indexes**:
```xpp
// Prefer indexed fields
select custTable
    index hint AccountIdx
    where custTable.AccountNum == _accountNum;
```

2. **Limit result sets**:
```xpp
// Use firstOnly when appropriate
select firstonly custTable
    where custTable.AccountNum == _accountNum;
```

3. **Use joins instead of loops**:
```xpp
// Good: Use joins
while select custTable
    join dirPartyTable
        where dirPartyTable.RecId == custTable.Party
{
    // Process
}

// Bad: Loop with selects
while select custTable
{
    dirPartyTable = DirPartyTable::findRec(custTable.Party);
    // Process
}
```

### API Optimization

1. **Batch processing**:
   - Process 50-100 records per API call
   - Avoid single-record calls

2. **Async processing**:
   - Use batch jobs for large datasets
   - Don't block user interface

3. **Caching**:
```xpp
private static Map customerCache;

public static CustTable getCachedCustomer(CustAccount _accountNum)
{
    if (!customerCache)
    {
        customerCache = new Map(Types::String, Types::Record);
    }
    
    if (!customerCache.exists(_accountNum))
    {
        customerCache.insert(_accountNum, CustTable::find(_accountNum));
    }
    
    return customerCache.lookup(_accountNum);
}
```

## Version Control

### Git Workflow

1. **Create feature branch**:
```bash
git checkout -b feature/add-custom-field
```

2. **Make changes and commit**:
```bash
git add .
git commit -m "Add custom field to account contract"
```

3. **Push and create PR**:
```bash
git push origin feature/add-custom-field
# Create pull request in GitHub/Azure DevOps
```

### Best Practices

- Commit frequently with descriptive messages
- Don't commit generated files
- Use `.gitignore` for build outputs
- Review before committing

## Documentation

### Code Comments

Use XML documentation:

```xpp
/// <summary>
/// Retrieves customer accounts based on filter criteria
/// </summary>
/// <param name="_fromDate">Start date for filtering</param>
/// <param name="_toDate">End date for filtering</param>
/// <returns>List of account data contracts</returns>
public List getAccounts(TransDate _fromDate = dateNull(), 
                       TransDate _toDate = dateNull())
{
    // Implementation
}
```

### Update Documentation

When making changes:
1. Update README.md
2. Update API_INTEGRATION.md if API changes
3. Update this DEVELOPER_GUIDE.md
4. Add comments to complex code sections

## Resources

### Microsoft Documentation

- [D365 F&O Development](https://docs.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/)
- [X++ Language Reference](https://docs.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/dev-ref/xpp-language-reference)
- [Best Practices](https://docs.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/dev-ref/best-practices)

### Internal Resources

- Architecture documentation
- API specifications
- Team wiki

## Support

For development questions:
- Check existing documentation
- Review similar implementations
- Ask team lead or senior developer
- Create GitHub issue for bugs
