# What is the SAS CoV App?
Adopting models is hard. Analytics lifecycle management is hard.

This project was bootstrapped with the [Create SAS App](https://github.com/Boemska/create-sas-app) Carbon Design App. This is an extension of Facebook's [Create React App](https://github.com/facebook/create-react-app) and provides SAS and JavaScript developers a standard and effortless way to get started wih developing Apps for the SAS platform.


## Getting started
In order to get the application up and running in no time at all, run the following 3 commands from within this folder:

### `yarn install` 
Install all the dependencies listed within `package.json` in the local `node_modules` folder.

### `yarn run configure`
In the `package.json` for this quick-start application we hav defined a scripts object called `configure`, this command will run the specified [configure] script. The `configure` script is a guided process for connecting your local quick-start application to your remote SAS instance.

### `yarn start`
Runs the app in the development mode.<br />
Open [https://localhost:3000](https://localhost:3000) to view it in the browser.

The app uses a proxy to communicate with the server so it has to open on a an https connection

The page will reload if you make edits.<br />
You will also see any lint errors in the console.


## Other technical commands

### `yarn test`

Launches the test runner in the interactive watch mode.<br />
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `yarn build`

Builds the app for production to the `build` folder.<br />
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.<br />
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
