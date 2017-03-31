# publish-webapplicationversion
Powershell Function to take a WebApplication build, compress it into a *.nupkg file with 7zip, and drop the created file into a desired repository.

# Design Scope
Publish-WebApplicationVersion
Will accept a path to the root folder of a Web Application, compress that build into a .nupkg file using 7zip and publish it to a specified Chocolatey Repository in the correct folder structure (see below).  It will accept a version number to publish as specifically, otherwise it will increment the version number by 0.1 from the previous version in the Chocolatey repository. Should be able to accept parameters on the pipeline, which would allow storing of default-settings in a CSV, and then being able to publish the latest version with minimal inputs.

Desired folder structure of

# Usage Examples

## Parameters
* Path (to the build)
* Name (of the WebApplication)
* Destination (the root folder of the Chocolatey Repository)
* Version (build version number in decimal form)
* 

~~~powershell
Publish-WebApplicationVersion -Path 
~~~
