###################Load Assembly for creating form & button######

[void][System.Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName( "Microsoft.VisualBasic")

#####Define the form size & placement
function DialogChooseVersion
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$buildVersion,
        [Parameter(Mandatory = $true)]
        [string]$currentBuildVersion
    )

    Write-Host "Running dialog choose box"
    $form = New-Object "System.Windows.Forms.Form";
    $form.Width = 500;
    $form.Height = 190;
    $form.Text = "Choose version to bump";
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;
    $form.ControlBox = "true"
    $Form.TopMost = "true"

    ############Define combobox
    $dropdown = New-Object "System.Windows.Forms.combobox";
    $dropdown.Left = 100;
    $dropdown.Top = 30;
    $dropdown.width = 200;
    $dropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;

    ###############"Add descriptions to combo box"##############
    $DropDownArray = @("patch", "minor", "major")

    ForEach ($Item in $DropDownArray)
    {
        $dropdown.Items.Add($Item) | Out-Null
    }

    $dropdown.SelectedItem = $buildVersion

    #############define OK button
    $button = New-Object "System.Windows.Forms.Button";
    $button.Left = 310;
    $button.Top = 30;
    $button.Width = 100;
    $button.Text = “Ok”;
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $Button.Font = New-Object System.Drawing.Font("Helvetica", 11)

    #############define Label
    $textLabel = New-Object "System.Windows.Forms.label"
    $textLabel.Left = 100
    $textLabel.Top = 5
    $textLabel.Width = 200
    $textLabel.BackColor = "Transparent"
    $textLabel.ForeColor = "black"
    $textLabel.Text = "Choose version bump number: "

    #############define bump version Label
    $textbumpLabel = New-Object "System.Windows.Forms.label"
    $textbumpLabel.Left = 100
    $textbumpLabel.Top = 60
    $textbumpLabel.Width = 200
    $textbumpLabel.BackColor = "Transparent"
    $textbumpLabel.ForeColor = "black"


    #############define what happens when you choose a value in the dropdown
    $dropdown.Add_SelectedIndexChanged({
        $script:locationResult = $dropdown.selectedItem;
        write-host "Selected value: $currentBuildVersion"
        $dropDownValueFound = bumpVersion($script:locationResult, $currentBuildVersion)
        write-host "Found value: $dropDownValueFound"
        $textbumpLabel.Text = "Old: $currentBuildVersion => New: " +  $dropDownValueFound
    })


    ############# This is when you have to close the form after getting values
    $eventHandler = [System.EventHandler]{
        $dropdown.Text;
        $form.Close();
    };
    $button.Add_Click($eventHandler);

    #############Add controls to all the above objects defined
    $form.Controls.Add($button);
    $form.Controls.Add($textLabel);
    $form.Controls.Add($textbumpLabel);
    $form.Controls.Add($dropdown);

    #################return values
    $button.add_Click({
        $script:locationResult = $dropdown.selectedItem # or this to retrieve the user selection
    })

    $form.Controls.Add($button)
    $form.Controls.Add($cBox2)

    $form.ShowDialog()

    #return $script:locationResult
}


function bumpVersion($kind, $version) {

    $version = "1.0.0"
    $major, $minor, $patch = $version.split('.')

    switch ($kind) {
        "major" {
            $major = [int]$major + 1
        }
        "minor" {
            $minor = [int]$minor + 1
        }
        "patch" {
            $patch = [int]$patch + 1
        }
    }

    return [string]::Format("{0}.{1}.{2}", $major, $minor, $patch)
    }

#### For test purpose
#DialogChooseVersion -buildVersion "1.0.0" -currentBuildVersion "1.0.0"
