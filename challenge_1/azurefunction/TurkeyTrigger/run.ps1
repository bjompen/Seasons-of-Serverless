using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Salt (in cups) = 0.05 * lbs of turkey
# Water (gallons) = 0.66 * lbs of turkey
# Brown sugar (cups) = 0.13 * lbs of turkey
# Shallots = 0.2 * lbs of turkey
# Cloves of garlic = 0.4 * lbs of turkey
# Whole peppercorns (tablespoons) = 0.13 * lbs of turkey
# Dried juniper berries (tablespoons) = 0.13 * lbs of turkey
# Fresh rosemary (tablespoons) = 0.13 * lbs of turkey
# Thyme (tablespoons) = 0.06 * lbs of turkey
# Brine time (in hours) = 2.4 * lbs of turkey
# Roast time (in minutes) = 15 * lbs of turkey

enum MassTypes {
    cups
    dl
    tablespoons
}

enum FluidTypes {
    gallons
    litres
}

class mass {
    [double]$cups
    [double]$dl
    [double]$tablespoons

    mass(
        [double]$value,
        [MassTypes]$MassType
    ) {
        switch ($MassType) {
            'cups' { 
                $this.cups = $value
                $this.dl = $value * 2.36588237
                $this.tablespoons = $value * 16
            }
            'dl' { 
                $this.cups = $value * 0.422675284
                $this.dl = $value
                $this.tablespoons = $value * 6.76280454
            }
            'tablespoons' { 
                $this.cups = $value * 0.0625
                $this.dl = $value * 0.147867648
                $this.tablespoons = $value
            }
        }
    }
}

class fluid {
    [double]$gallons
    [double]$litres

    fluid(
        [double]$value,
        [FluidTypes]$FluidType
    ) {
        switch ($FluidType) {
            'gallons' { 
                $this.gallons = $value
                $this.litres = $value * 3.78541178
            }
            'litres' { 
                $this.gallons = $value * 0.264172052
                $this.litres = $value
            }
        }
    }
    
}

function Get-turkey {
    param (
        $TurkeyWeight
    )
    
    $Recepie = @{
        'LbsWeight' = $TurkeyWeight
        'KiloWeight' = [math]::Round(($TurkeyWeight * 0.45359237), 2)
        'Salt' = [mass]::New( ($TurkeyWeight * 0.05), 'cups' )
        'water' = [fluid]::New( ($TurkeyWeight * 0.66), 'gallons' )
        'BrownSugar' = [mass]::New( ($TurkeyWeight * 0.13), 'cups' )
        'Shallots' = $TurkeyWeight * 0.2
        'GarlicCloves' = $TurkeyWeight * 0.4
        'PepperCorns' = [mass]::New( ($TurkeyWeight * 0.13), 'tablespoons' )
        'JuniperBerries' = [mass]::New( ($TurkeyWeight * 0.13), 'tablespoons' )
        'Rosemary' = [mass]::New( ($TurkeyWeight * 0.13), 'tablespoons' )
        'Thyme' = [mass]::New( ($TurkeyWeight * 0.06), 'tablespoons' )
        'BrineTime' = $TurkeyWeight * 2.4
        'RoastTime' = $TurkeyWeight * 15
    }

    $Recepie
}

Function Out-RealMeasurements {
    Param (
        $BrineObj
    )
    
    $BrineTime = New-Timespan -Hours $brineObj.BrineTime
    $RoastTime = New-Timespan -minutes $brineObj.RoastTime
@"
$($BrineObj.KiloWeight) Kilos of bird
{0:N1} DL Salt 
{1:N1} Litres Water
{2:N1} DL Brown sugar 
{3} Shallots
{4} Cloves of garlic
{5:N1} tablespoons of Whole peppercorns
{6:N1} tablespoons of Dried juniper berries
{7:N1} tablespoons of Fresh rosemary
{8:N1} tablespoons of Thyme
Brine for $($brineTime.TotalHours) hours and $($brineTime.minutes) minutes.  
Roast for $($RoastTime.hours) hours and $($RoastTime.minutes) minutes.
"@ -f   $brineObj.Salt.dl, 
        $brineObj.water.litres, 
        $brineObj.BrownSugar.dl, 
        [math]::Ceiling($brineObj.Shallots),
        [math]::Ceiling($brineObj.GarlicCloves),
        $brineObj.PepperCorns.tablespoons,
        $brineObj.JuniperBerries.tablespoons,
        $brineObj.rosemary.tablespoons,
        $brineObj.Thyme.tablespoons
}
Function Out-AmericanMeasurements {
    Param (
        $BrineObj
    )
    
    $BrineTime = New-Timespan -Hours $brineObj.BrineTime
    $RoastTime = New-Timespan -minutes $brineObj.RoastTime
@"
$($BrineObj.LbsWeight) Lbs of bird
{0:N1} Cups Salt 
{1:N1} Gallons Water
{2:N1} Cups Brown sugar 
{3} Shallots
{4} Cloves of garlic
{5:N1} tablespoons of Whole peppercorns
{6:N1} tablespoons of Dried juniper berries
{7:N1} tablespoons of Fresh rosemary
{8:N1} tablespoons of Thyme
Brine for $($brineTime.TotalHours) hours and $($brineTime.minutes) minutes.  
Roast for $($RoastTime.hours) hours and $($RoastTime.minutes) minutes.
"@ -f   $brineObj.Salt.cups, 
        $brineObj.water.gallons, 
        $brineObj.BrownSugar.cups, 
        [math]::Ceiling($brineObj.Shallots),
        [math]::Ceiling($brineObj.GarlicCloves),
        $brineObj.PepperCorns.tablespoons,
        $brineObj.JuniperBerries.tablespoons,
        $brineObj.rosemary.tablespoons,
        $brineObj.Thyme.tablespoons
}


# Interact with query parameters or the body of the request.
[int]$inputweight = $Request.Query.weight
$Measurements = $Request.Query.realmeasurements

if ([string]::IsNullOrEmpty($inputweight)) {
    $inputweight = 10
}
if (-not [string]::IsNullOrEmpty($Measurements)) {
    $body = out-RealMeasurements (Get-turkey -TurkeyWeight $inputweight)
}
else {
    $body = out-AmericanMeasurements (Get-turkey -TurkeyWeight $inputweight)
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
StatusCode = [HttpStatusCode]::OK
Body = $body
})
