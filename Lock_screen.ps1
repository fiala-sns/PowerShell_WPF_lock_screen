[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| Out-Null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')       				| Out-Null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.IconPacks.dll')       				| Out-Null


function LoadXml ($global:filename) {
    $XamlLoader = (New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

# Load MainWindow
$XamlMainWindow = LoadXml("Lock_screen.xaml")
$Reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($Reader)


$Enter_TS = $Form.findname("Enter_TS") 
$Typed_PWD = $Form.findname("Typed_PWD") 
$PWD_Status = $Form.findname("PWD_Status") 



# Add custom type to hide the taskbar
# Thanks to https://stackoverflow.com/questions/25499393/make-my-wpf-application-full-screen-cover-taskbar-and-title-bar-of-window
$CSharpSource = @"
using System;
using System.Runtime.InteropServices;

public class Taskbar
{
    [DllImport("user32.dll")]
    private static extern int FindWindow(string className, string windowText);
    [DllImport("user32.dll")]
    private static extern int ShowWindow(int hwnd, int command);

    private const int SW_HIDE = 0;
    private const int SW_SHOW = 1;

    protected static int Handle
    {
        get
        {
            return FindWindow("Shell_TrayWnd", "");
        }
    }

    private Taskbar()
    {
        // hide ctor
    }

    public static void Show()
    {
        ShowWindow(Handle, SW_SHOW);
    }

    public static void Hide()
    {
        ShowWindow(Handle, SW_HIDE);
    }
}
"@
Add-Type -ReferencedAssemblies 'System', 'System.Runtime.InteropServices' -TypeDefinition $CSharpSource -Language CSharp

powershell $PSScriptRoot\Set_CtrlAltDel.ps1 -DisableAll


$IT_PWD = "toto"
$Enter_TS.Add_Click({
        $Script:Enter_PWD = $Typed_PWD.Password  
        If ($Enter_PWD -ne "") {
            If ($Enter_PWD -eq $IT_PWD) {
                $Script:Password_Status = $True
                powershell .\Set_CtrlAltDel.ps1 -EnableAll
                [Taskbar]::Show()							
                $Form.Close()
            }	
            Else {
                $PWD_Status.Content = "Bad password !!!"
            }
        }
        Else {
            [System.Windows.Forms.MessageBox]::Show("Please type a Task sequence password", "Oops, Task Sequence error")		
        }
    })


$Form.ShowDialog() | Out-Null

