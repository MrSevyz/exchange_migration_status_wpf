#========================================================================
#
# Tool Name	: migration_status
# Author 	: luca
#
#========================================================================

##Initialize######
[System.Void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  				
[System.Void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[System.Reflection.Assembly]::LoadFrom((Join-Path (pwd) 'assembly\MahApps.Metro.dll')) | out-null
[System.Reflection.Assembly]::LoadFrom((Join-Path (pwd) 'assembly\System.Windows.Interactivity.dll')) | out-null


[String]$ScriptDirectory = split-path $myinvocation.mycommand.path

function LoadXml ($global:filename)
{
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

# Load MainWindow
$XamlMainWindow=LoadXml("$ScriptDirectory\main.xaml")
$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form=[Windows.Markup.XamlReader]::Load($Reader)



$XamlMainWindow.SelectNodes("//*[@Name]") | %{
    try {Set-Variable -Name "$("WPF_"+$_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable *WPF*
}
Get-FormVariables


$WPF_Close.add_Click({

   $Form.Close()

})
$WPF_btncnt.add_Click({
	
    $migrationBatches = Get-MigrationBatch
    $usersStatistics = @()
    foreach ($batch in $migrationBatches) {
        $usersStatistics += Get-MigrationUser -BatchId $batch.Identity | Get-MigrationUserStatistics |select BatchId, Identity, StatusDetail, PercentageComplete, EstimatedTotalTransferSize, SkippedItemCount, BytesTransferred, TotalItemsInSourceMailboxCount, SyncedItemCount, CreatedTime, LastSuccessfulSyncTime | ForEach-Object {
            $_.PercentageComplete = [int]$_.PercentageComplete
            #write-host $_
			$_
			
        }
    }
    $WPF_dgrid1.ItemsSource = $usersStatistics


})

$WPF_btncred.add_Click({
    Connect-ExchangeOnline 
    $migrationBatches = Get-MigrationBatch
    $usersStatistics = @()
    foreach ($batch in $migrationBatches) {
        $usersStatistics += Get-MigrationUser -BatchId $batch.Identity | Get-MigrationUserStatistics |select BatchId, Identity, StatusDetail, PercentageComplete, EstimatedTotalTransferSize, BytesTransferred, TotalItemsInSourceMailboxCount, SyncedItemCount, CreatedTime, LastSuccessfulSyncTime | ForEach-Object {
            $_.PercentageComplete = [int]$_.PercentageComplete
            #write-host $_
			$_
			
        }
    }
    $WPF_dgrid1.ItemsSource = $usersStatistics

	
}) 


# Make PowerShell Disappear
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
 
# Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()


$Form.ShowDialog() | Out-Null


