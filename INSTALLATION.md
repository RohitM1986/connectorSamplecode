# Installation Guide - CRM F&O PoC Package

## Prerequisites

### System Requirements
- **Microsoft Dynamics 365 Finance & Operations** (Version 10.0 or higher)
- **Visual Studio 2017 or later** with Dynamics 365 extension
- **.NET Framework 4.7.2** or higher
- **PowerShell 5.1** or higher
- **Administrator access** to D365 F&O environment
- **Developer license** for D365 F&O

### Required Permissions
- System Administrator role in D365 F&O
- Access to Application Object Tree (AOT)
- Database synchronization rights
- Batch job creation permissions

## Installation Steps

### 1. Download and Extract Package

```bash
# Clone or download the repository
cd /path/to/packages/
git clone <repository-url> CRMFOpoC

# D365 F&O Environment URL: https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com/

# Or extract the zip file
unzip CRMFOpoC.zip -d CRMFOpoC
```

### 2. Import into Visual Studio

1. Open **Visual Studio**
2. Go to **Dynamics 365 > Model Management > Import Model**
3. Select the `CRMFOpoC` package
4. Choose import options:
   - Model name: `CRMFOpoC`
   - Layer: `ISV`
   - Publisher: `VTX`
   - Environment: `https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com/`
5. Click **Import**

### 3. Build the Solution

1. In Visual Studio, open **Solution Explorer**
2. Right-click on the solution
3. Select **Build Solution** (Ctrl+Shift+B)
4. Wait for build to complete successfully
5. Check **Output** window for any errors

### 4. Deploy to D365 F&O

#### Option A: Using Visual Studio

1. In Solution Explorer, right-click the project
2. Select **Dynamics 365 > Deploy Model**
3. Select target environment
4. Wait for deployment to complete

#### Option B: Using PowerShell Script

```powershell
cd CRMFOpoC\Scripts

.\Deploy-Package.ps1 `
    -Environment "https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com/" `
    -PackagePath "..\Output" `
    -ModelName "CRMFOpoC" `
    -SyncDatabase
```

### 5. Database Synchronization

1. Open **Dynamics 365 F&O web client**
2. Go to **System administration > Database > SQL Administration**
3. Click **Synchronize database**
4. Wait for synchronization to complete

Or use command line:

```cmd
Microsoft.Dynamics.AX.Deployment.Setup.exe ^
    -bindir "C:\AOSService\PackagesLocalDirectory" ^
    -metadatadir "C:\AOSService\PackagesLocalDirectory" ^
    -sqlserver "." ^
    -sqldatabase "AXDB" ^
    -setupmode sync ^
    -syncmode fullall
```

### 6. Verify Installation

1. Navigate to **Organization administration > Setup**
2. Look for **CRM Integration Parameters** menu item
3. Open it to verify the form loads correctly
4. Check that all fields are visible

## Post-Installation Configuration

### 1. Configure Integration Parameters

1. Go to **Organization administration > Setup > CRM Integration Parameters**
2. Configure the following settings:

| Field | Description | Example |
|-------|-------------|---------|
| **Enabled** | Enable/disable integration | Yes |
| **API Endpoint** | External API URL | https://api.example.com/v1/sync |
| **API Key** | Authentication key | your-api-key-here |
| **Default Customer Group** | Default filter | 10 |
| **Batch Size** | Records per batch | 100 |
| **Timeout (seconds)** | API timeout | 30 |
| **Max Retries** | Retry attempts | 3 |

3. Click **Save**

### 2. Test API Connection

1. In **CRM Integration Parameters** form
2. Click **Test Connection** button
3. Verify "Connection Successful" message

Or use PowerShell script:

```powershell
.\Scripts\Test-Integration.ps1 `
    -APIEndpoint "https://api.example.com/v1/sync" `
    -APIKey "your-api-key" `
    -TestConnection
```

### 3. Set Up Security Roles

1. Go to **System administration > Security > Security configuration**
2. Assign the following privileges to appropriate roles:
   - **CRMIntegrationMaintain** - Full access
   - **CRMIntegrationView** - Read-only access

### 4. Configure Batch Job (Optional)

1. Go to **System administration > Inquiries > Batch jobs**
2. Click **New**
3. Configure:
   - **Description**: CRM Integration Batch
   - **Batch class**: CRMIntegrationBatch
4. Click **Add batch task**
5. Set recurrence:
   - **Pattern**: Daily
   - **Start time**: 02:00 AM
6. Click **OK** and **Activate**

## Manual Execution

### From D365 F&O UI

1. Go to **Organization administration > Periodic > CRM API Integration**
2. Set parameters:
   - Customer Group (optional)
   - From Date (optional)
   - To Date (optional)
   - Batch Size
3. Click **OK** to execute

### From X++ Code

```xpp
static void RunCRMIntegration(Args _args)
{
    CRMExternalAPIIntegration integration;
    
    integration = new CRMExternalAPIIntegration();
    integration.parmCustGroup('10');
    integration.parmBatchSize(50);
    integration.run();
}
```

## Monitoring and Logging

### View Integration Logs

1. Go to **Organization administration > Inquiries > CRM Integration Log**
2. Filter by:
   - Date range
   - Success/Failure status
   - Request ID

### Check Event Log

1. Go to **System administration > Inquiries > Database > Database log**
2. Filter for table: **CRMIntegrationLog**

## Troubleshooting

### Build Errors

**Error**: Missing references
```
Solution: Ensure all dependent models are referenced in Visual Studio
```

**Error**: Compiler errors
```
Solution: Clean and rebuild solution (Build > Clean, then Build > Rebuild)
```

### Deployment Errors

**Error**: Model already exists
```
Solution: Uninstall existing model first or use update deployment
```

**Error**: Database sync failed
```
Solution: Check SQL permissions and run sync manually
```

### Runtime Errors

**Error**: API connection timeout
```
Solution: Increase timeout setting in CRM Integration Parameters
```

**Error**: Authentication failed
```
Solution: Verify API Key is correct and not expired
```

**Error**: No accounts found
```
Solution: Check filter criteria and verify customer data exists
```

## Uninstallation

### 1. Remove Batch Jobs

1. Go to **System administration > Inquiries > Batch jobs**
2. Find CRM Integration batch jobs
3. Click **Delete**

### 2. Remove Data (Optional)

```sql
-- Backup first!
DELETE FROM CRMIntegrationLog;
DELETE FROM CRMIntegrationParameters;
```

### 3. Uninstall Model

```cmd
AXUtil.exe /model:CRMFOpoC /uninstall
```

Or from Visual Studio:
1. **Dynamics 365 > Model Management > Uninstall Model**
2. Select **CRMFOpoC**
3. Click **Uninstall**

### 4. Synchronize Database

Run database synchronization to remove tables and objects.

## Support

For issues or questions:
- Check the log files in `CRMIntegrationLog` table
- Review the error messages in D365 Infolog
- Contact your system administrator

## Version Information

- **Package Version**: 1.0.0
- **Model Version**: 1.0.0.0
- **Minimum D365 F&O Version**: 10.0
- **Last Updated**: February 2026
