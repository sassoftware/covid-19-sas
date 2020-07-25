# COVID-19 CCF SAS Viya App

## About this App

Frontline ER physician and Co-Creator of the Netflix series Pandemic, Ryan McGarry MD, had this to say when [he spoke to SAS' Alyssa Farrell at this year's SAS Global Forum Executive Connection](https://www.sas.com/en_us/events/sas-global-forum/analytics-executive.html):

> "You can come with me any day, and I'll show you all the ways that you can help clinical frontline staff - as far as just the interfaces that we work with. There's so much room for improvement here, I'm not even sure we have enough time to cover it all. Of all areas of the world, how is it that healthcare seems to be so far behind on the frontline in terms of interface, and particularly the user experince?" 

This project explores a solution to the problem stated by Dr. McGarry. It implements an alternative interface to the same resource optimisation & forecasting code that powers the Visual Analytics-based CCF application in this repository. It is not as full-featured as the VA app, instead focusing on simplicity, minimal load time, and context switching efficiency.

Usability within a clinical setting is a primary consideration. The interface and its components are designed for [stylus-based interaction](https://ieeexplore.ieee.org/document/4588449), to be usable while wearing gloves/PPE, and to run on easy-to-sterilize devices (i.e. tablets). While the design primarily targets iPad and Apple Pencil, the app will work just as well on similar Android, Windows or ChromeOS stylus-enabled devices. It is shown here running on a 10.5" 2017 iPad Pro.  

<p align="center">
<img src="./covid-app-ipad.gif">
</p>

Being a CSA-bootstrapped Progressive Web App, the app can be deployed to mobile devices directly without any need for an App Store or associated third-party approval processes. It can also be configured to receive updates without any user intervention. Other features of CSA, such as project sharing, are described in the readme of the [main Boemska CSA repository](https://github.com/boemska/create-sas-app).

This project is an example of how easily Open Source technology can be used to build and deploy secure, operational tooling in environments where SAS is an available platform. While epidemiological analysis might not require the user to wear gloves, the code and approach used here can very easily be adapted to more targeted use cases, enabling mass deployment of SAS AI & ML powered tooling to frontline clinical staff.


## About CSA

As mentioned above, this project was bootstrapped with the [Create SAS App](https://github.com/Boemska/create-sas-app) Carbon Design App. This is an extension of Facebook's [Create React App](https://github.com/facebook/create-react-app) and provides SAS and JavaScript developers a standard and effortless way to get started wih developing Apps for the SAS platform. If you are interested in developing this app further, take a look at the Create SAS App repo.


## Running this app

The following section details the steps required to deploy and run the Boemska Hospital Resource Optimization SAS Viya App. The deployment of this app involves two steps:

 - Deploying the back-end components, in the form of a Viya Job Execution Service Job and a set of h54s macros to be included by that job
 - Deploying the front-end components, in the form of a directory containing some files to be served by the Web Server (.html, .js, .css, images, etc)

This Readme contains details on that process. 

### Configure the backend

#### Install the h54s adapter

This app is bootstrapped by Boemska's [IBM Carbon Design Create SAS App template](https://github.com/Boemska/create-sas-app/tree/master/carbon-ui) which is powered by Boemska's [h54s](https://github.com/Boemska/h54s). In order to run this application, the SAS macros that support h54s need to be made available on the server. To do this:

1. Either clone the [h54s](https://github.com/Boemska/h54s) repository or copy the [h54s.sas](https://github.com/Boemska/h54s/blob/master/sasautos/h54s.sas) file to your SAS Viya Compute Server node(s). Ensure that the h54s.sas file is readable by any user who can start a SAS session (i.e. read permissions should be granted to the `sas` group).
1. If you are able to, modify your Compute Server `autoexec_usermods.sas` file found in `/opt/sas/viya/config/etc/compsrv/default` and add the following lines, updating the path to your `h54s.sas` file:

	```sas
	%include "/path/to/h54s.sas" ;
	```

  If you are for whatever reason unable to modify `autoexec_usermods.sas` directly, you can add the same `%include` code snippet to the beginning of the code deployed to the server as part of the [Deploy the services](#deploy-the-services) step below. 

#### Configure the model store location	

Either clone this repository or copy the CCF folder to your Viya Compute Server node(s). You will configure the app's services to use this location in a later step of the configuration process. More information on this is available in the [Getting started with the code](https://github.com/sassoftware/covid-19-sas/tree/master/CCF#getting-started-with-the-code) section of the CCF folder of this repository.

#### Configure and deploy the services

The app relies on two compute services:

- startupService  
The app's bootstrap service (`startupService`) must be dfeined as a Job in the Viya Job Execution Service. The `startupService` is used by the application to initialize the user interface; for this app, we use the `startupService` to make the labels for each of the input types in the scenario generator user editable. This may be deprecated in future for performance reasons in favour of a simpler file in the files service. But for now, it's a JES job.

- runModel  
The `runModel` service is generated by the main build script and runs the models against the supplied scenarios. This is the service that will actually run the CCF model code against the scenarios that are generated by the user (`runModel`). 


On Viya, the services are registered as Job Definitions using the SASJobExecution web application (`https://{yourViyaServer}/SASJobExecution`). 

1. Create a SAS folder called `getData` in a folder where you have write permissions. Something like `/Public/Covid App`.
1. Right click on the new `getData` folder and select new file. Give the file a name `startupService`, provide and optional _Description_, ensure the type is set to **Job Definition** and ensure the server type is set to **Compute**.
1. Open the newly created job and copy the contents of the `startupService.sas` file from the _CCF/build/Boemska_ folder to the new job and click save.
1. Right click on the `startupService` job definition and select properties. From the properties menu select "Parameters". Add the following parameter and then click save:
	* Name: `_output_type`
	* Default value: `html`
	* Field type: `Character`
	* Required: `false` 
1. Right click on the new `getData` folder and select new file. Give the file a name `runModel`, provide and optional _Description_, ensure the type is set to **Job Definition** and ensure the server type is set to **Compute**.
1. Open the newly created job and copy the contents of the `runModel.sas` file from the _CCF/build/Boemska_ folder to the new job and click save. Edit the following lines:
	* Line 19 - Set the location of your `&homedir` this is the location of the CCF folder of your repository
	* Lines 25 & 26 - Configure these options as per your licensed product set
1. Right click on the `runModel` job definition and select properties. From the properties menu select "Parameters". Add the following parameter and then click save:
	* Name: `_output_type`
	* Default value: `html`
	* Field type: `Character`
	* Required: `false` 


### Get JavaScript dependencies and configure the JavaScript app 

1. Run `yarn install`. This will install all the dependencies listed within `package.json` into a local `node_modules` folder.
1. Run `yarn run configure`. This command will run the `configure` script, a guided process for connecting your local quick-start application to your remote SAS instance. It will ask you for the following:  
    - The fully qualified web address of your SAS Viya Server. This is the address of the server as accessed through your web browser.
	- The server type. Choose SAS Viya, as that is what this app currently targets.
	- The SAS Folder path for back-end services. This is the path from Step 1 in the [Deploy the services](#deploy-the-services) section above - the folder in which you created the `getData` folder, not the `getData` folder itself.

### Build and run the app in Development mode

From within the `App` folder, run `yarn start`. This will build the app and run it in the CRA development mode.  

Open [https://localhost:3000](https://localhost:3000) to view it in the browser (this should happen automatically)

If the SAS Viya server you are communicating with is secured with HTTPS (which it should be), the development mode app will also serve the development mode app from a HTTPS connection on localhost. It is generally safe to ignore the warnings about the localhost certificate having an unknown issuer, as the certificate for your localhost is self-signed and you will be communicating via loopback. If for any reason you would like to configure localhost SSL with a custom SSL certificate, follow the official [steps from the Create React App documentation](https://create-react-app.dev/docs/using-https-in-development/). 

1. As you edit the app, the page will reload. You will also see any lint errors in the console. Develop away.

### Build the app in Production mode and deploy it

1 From within the `App` folder, run `yarn build`. This will compile a production-optimized build of the app and place it in the `build` folder. The build is minified and, the filenames include the hashes.  

Your app is ready to be deployed! A very simple way of doing this on SAS Viya is to copy that `build` folder to the the httpd root on the machine hosting the `sas-viya-httpproxy-*` service. For example, copying that build folder to `/var/www/html/build` will make the app accessible through `https://[yourViyaServer]/build`. Renaming the `build` folder contained within that `var/www/html` folder to something like `/var/www/html/covid-19` will change the app URL so that it is accessible via `https://[yourViyaServer]/covid-19/`.


### Boemska AppFactory

If you are deploying and developing this application using [Boemska AppFactory](https://boemskats.com/products/appfactory/) use the following to synchronise with your AF public workspace:

1. From the _App_ folder of this repository run `yarn watch`
1. In another terminal again, change directory to the build folder and run: `bap-sync --serverUrl https://[yourAFServer]/apps/ --repoUrl repo/dev/ --workspaceID *** --authToken *** --excludes node_modules`
