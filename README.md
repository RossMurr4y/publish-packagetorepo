# Publish-PackageToRepo
Powershell Function to take a package build, compress it into a chosen archive filetype with 7zip, and drop the output archive into a designated repository.

# Design Scope
Will accept a File to the root folder of a package, compress that build into an archive filetype using 7zip and publish it to a chosen package repository.  It will accept a version number to publish as specifically, otherwise it will increment the version number by the smallest possible decimal increment from the previous version of the same name in the chosen repository. Should be able to accept parameters via the pipeline. Logging of both successful and failed attempts should be made to a logs folder within the repository, but can be overwritten if a new log file location is provided.

## Supported Archive Types
* .nupkg
* .zip
* .7zip

# Usage Examples

## Input Parameters
* File (to the build)
* Name (of the WebApplication)
* Destination (the root folder of the Chocolatey Repository)
* Version (build version number in decimal form, or the word 'Incremental')
* Log (Location of the logging directory, or 'disable')
* Archive (The compression filetype to output to the repo)

## Example 1
~~~powershell
Publish-PackageToRepo -File 'C:\builds\MyPkg\','C:\builds\OtherPkg' -Version '1.2.3.4' -Destination '\\NETWORK\Share$\MyRepo\' -Log 'D:\Logs\' -Archive '7zip'
~~~
### **Explained:**
The first example shows that the File, Name (missing), Version, Log, Archive and Destination parameters are all strings. Note that File accepts multiple strings into an array.

## Example 2
~~~powershell
Publish-PackageToRepo 'C:\builds\MyPkg\' -Name 'MyImportantThing' -Version 'Incremental' -Dest '\\NETWORK\Share$\MyRepo\' -Log 'disable' -Archive 'nupkg'
~~~ 
### **Explained:**
The above example shows that the File parameter is positional and does not have to be specified if first. The Version parameter this time uses the word 'Incremental', which would increase the package version by the bare minimum from any existing package version (or use 0.0.0.1 if none exists). Additionally, the Destination parameter has an alias of 'Dest'. The Log parameter is not specified, indicating that it will use its default value of '$Destination\Logs\'. Name is specified here, so it will be used in place of the parent directory name. Instead of a log location being used, the word 'disable' will prevent all logging.

## Example 3
~~~powershell
Publish-PackageToRepo 'C:\builds\MyPkg\' -Dest '\\NETWORK\Share$\MyRepo\'
~~~
### **Explained:**
This example shows the bare minimum required to use the cmdlet. In this example, the following default values will be used: The name of the package will be the parent folder of the File param i.e 'MyPkg', the version number will increment by the bare minimum decimal value from whatever exists already in the Dest repository, the logs will be created in <Destination>\Logs, and the default Archive type will be zip.

## Example 4
~~~powershell
Import-CSV 'C:\tmp\PackageDefaults.csv' | Publish-PackageToRepo
~~~

### **Explained:**
This example shows that all of the default settings may be stored within a CSV file (with parameter names for headings) and can imported, then passed over the pipeline to the cmdlet. The intention here is to store regular deployment settings in a CSV, and then simply run the Import/Publish cmdlets. This could then be used for automated package archiving and deployment to the repository.