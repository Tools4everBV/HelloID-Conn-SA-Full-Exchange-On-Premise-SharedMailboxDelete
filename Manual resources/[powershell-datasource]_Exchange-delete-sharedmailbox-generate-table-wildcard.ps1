try {
    $adminSecurePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $adminCredential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $adminSecurePassword)
    
    $searchValue = ($dataSource.searchMailbox).trim()
    $searchQuery = "*$searchValue*"    

    $sessionOptionParams = @{
        SkipCACheck = $false
        SkipCNCheck = $false        
    }

    $sessionOption = New-PSSessionOption  @SessionOptionParams 

    $sessionParams = @{
        Authentication    = 'Default' 
        ConfigurationName = 'Microsoft.Exchange' 
        ConnectionUri     = $ExchangeConnectionUri 
        Credential        = $adminCredential        
        SessionOption     = $sessionOption       
    }

    $exchangeSession = New-PSSession @SessionParams

    Write-Information "Search query is '$searchQuery'" 
    
    $getMailboxParams = @{        
        Filter = "Alias -like '$searchQuery' -or name -like '$searchQuery' -or PrimarySmtpAddress -like '$searchQuery' -or DisplayName -like '$searchQuery'"   
        RecipientTypeDetails = 'SharedMailbox'
    }
   
    $invokecommandParams = @{
        Session      = $exchangeSession
        Scriptblock  = [scriptblock] { Param ($Params)Get-Mailbox @Params }
        ArgumentList = $getMailboxParams
    }

    Write-Information "Successfully connected to Exchange '$ExchangeConnectionUri'"  
    
    $mailboxes = Invoke-Command @invokeCommandParams   
    $mailboxes = $mailboxes | Sort-Object -Property DisplayName

    $resultCount = @($mailboxes).Count
    Write-Information "Result count: $resultCount"
        
    $resultMailboxes = [System.Collections.Generic.List[PSCustomObject]]::New()
    foreach ($mailbox in $mailboxes) { 
        
        $resultMailbox = @{
            DisplayName       = $mailbox.DisplayName
            Name              = $mailbox.Name
            Alias             =$mailbox.Alias
            Mailaddress       =$mailbox.PrimarySmtpAddress
            UserPrincipalName =$mailbox.userPrincipalName
        }
        $resultMailboxes.add($resultMailbox)

    }
    $resultMailboxes
    
    Remove-PSSession($exchangeSession)
  
}
catch {
    Write-Error "Error connecting to Exchange using the URI '$exchangeConnectionUri', Message '$($_.Exception.Message)'"
}

