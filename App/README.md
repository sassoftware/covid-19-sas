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

This project was bootstrapped with the [Create SAS App](https://github.com/Boemska/create-sas-app) Carbon Design App. This is an extension of Facebook's [Create React App](https://github.com/facebook/create-react-app) and provides SAS and JavaScript developers a standard and effortless way to get started wih developing Apps for the SAS platform.


## Getting started

To get the application up and running, run the following commands from within this folder:

### `yarn install` 

Install all the dependencies listed within `package.json` in the local `node_modules` folder.

### `yarn run configure`

This command will run the `configure` script, a guided process for connecting your local quick-start application to your remote SAS instance.

### `yarn start`

Runs the app in the development mode.  

Open [https://localhost:3000](https://localhost:3000) to view it in the browser.

If the app needs to use a proxy to communicate with the SAS server, it will open an https connection to localhost. It is generally safe to ignore the warnings, as the certificate for your localhost is self-signed and you will be comunicating via loopback. To configure localhost SSL with a custom SSL certificate, follow the [steps from the Create React App documentation](https://create-react-app.dev/docs/using-https-in-development/). 

As you edit the app, the page will reload.  

You will also see any lint errors in the console.

## Deploying back-end SAS code

TODO

## Other technical commands

### `yarn test`

Launches the test runner in the interactive watch mode.
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `yarn build`

Builds the app for production to the `build` folder.  

It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.  

Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `yarn watch`

Starts build with watch - used npm-watch with setthins in package.json
```javascript
"scripts": {
	...,
	"watch": "npm-watch"
},
"watch": {
	"build": "src/"
}
```

### `serve -s build`
Serve prod build locally. To use this first run
```javascript
yarn global add serve
```

### `yarn eject`

**Note: this is a one-way operation. Once you `eject`, you can’t go back!**

If you aren’t satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (Webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you’re on your own.

You don’t have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn’t feel obligated to use this feature. However we understand that this tool wouldn’t be useful if you couldn’t customize it when you are ready for it.

### To run development scripts follow
```text
1. yarn watch
2. in separated terminal run serve -s build
3. in separated terminal cd build and run bapsync script
```

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

### Code Splitting

This section has moved here: https://facebook.github.io/create-react-app/docs/code-splitting

### Analyzing the Bundle Size

This section has moved here: https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size

### Making a Progressive Web App

This section has moved here: https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app

### Advanced Configuration

This section has moved here: https://facebook.github.io/create-react-app/docs/advanced-configuration

### Deployment

This section has moved here: https://facebook.github.io/create-react-app/docs/deployment

### `yarn build` fails to minify

This section has moved here: https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify
