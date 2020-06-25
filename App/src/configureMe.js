const inquirer = require('inquirer');
const ora = require('ora');
const chalk = require('chalk');
const boxen = require('boxen');
const getRepoInfo = require('git-repo-info');
const fs = require('fs');


// define possible SAS environments
var sasEnvs = [
    {
        name: 'SAS Viya (3.4 or later)',
        value: "viya",
        short: "SAS Viya"
    },
    {
        name: 'SAS v9 (9.4m3 or later)',
        value: "v9",
        short: "SAS 9.4"
    }
];

// promise a XHR 
function checkSasServer (sasLocation) {
    return new Promise(function (resolve) {
        var XMLHttpRequest = require('xhr2');
        let request = new XMLHttpRequest();
        request.open('GET', sasLocation);
        request.onreadystatechange = function () {
            if (request.readyState === 4) {
                resolve(request)
            }
        };
        request.send();
    });
}

function renderIntro() {
    var info = getRepoInfo();
    const boxenOptions = {
        padding: 1,
        margin: 0,
        borderStyle: "round",
        borderColor: "#faad39"
    }
    
    const boxInfo = boxen(
        chalk.hex('#FAAD39').bold("Boemska h54s") + ' ' + chalk.white.bold("React PWA Seed") + '\n\n'
        + chalk.dim("sha:") + ' ' + info.abbreviatedSha + '\n'
        + chalk.dim("branch:") + ' ' + info.branch + '\n'
        + chalk.dim("root:") + ' ' + info.root 
        
        , boxenOptions );
        
        
        introText = '\n\n' + chalk.white.bold("CRA Dev Mode Configuration") + '\n\n'
        + chalk.dim("This script will help you configure your local development proxy with the " + "\n" +
        "details of your remote SAS server by running basic connectivity checks." + "\n" )
        return boxInfo + introText ;
    }
    
    async function configureSas() {
        // draw the intro text 
        console.clear();
        log = console.log;
        const introString = renderIntro();
        log(introString);
        
        const promptRes = await inquirer.prompt([
            {
                type: 'input',
                name: 'sasLocation',
                message: 'What is the full URL of your SAS server?',
                prefix: '-',
                default: 'https://teh.boemskats.com',
                validate: async (input) => {
                    if (!(input.startsWith('http://') || input.startsWith('https://'))) {
                    return 'URL must start with http:// or https://'
                } else if (input.split('/').length != 3) {
                    return "URL string expected to have exactly two slashes and must not contain trailing slashes or an application URI";
                } else {
                    try {
                        var serverUrl = new URL(input)
                        return true;
                    } catch {
                        return "The provided URL does not appear to be valid. "
                    }
                }
            }
        }, {
            type: 'list',
            name: 'sasType',
            prefix: '-',
            message: `Is this a SAS Viya or a SAS 9.4 server?`,
            choices: sasEnvs
        }
    ], function (answers) {
        sasLocation = answers.sasLocation;
        sasType = answers.sasType;
    });
    
    // list of microservices that our app uses that we want to validate endpoints for
    const msList = [
        {
            msName: "Identities endpoint",
            msLoc: "/identities"
        },
        {
            msName: "Files endpoint",
            msLoc: "/files"
        },
        {
            msName: "Folders endpoint",
            msLoc: "/folders"
        },
        {
            msName: "Projects endpoint",
            msLoc: "/projects"
        },
        {
            msName: "CAS Management endpoint",
            msLoc: "/casManagement"
        }
    ]
    
    // got the answers, now run the checks
    log('\nOk. Attempting autoconfiguration:');
    // this is a status rc 
    configurationResult = 'Ok';
    
    const connSpinner = ora('Checking SAS server connectivity').start();
    // check basic connectivity to SAS server with a XHR to root
    let basicOutcome = await checkSasServer(promptRes.sasLocation);
    // TODO: check that returned url and sent URL are the same protocol - otherwise we got redirected to HTTPS 
    if (promptRes.sasType === 'viya') {
        // root of Viya we expect a SASLogon redirect
        if (basicOutcome._url && basicOutcome._url.path && basicOutcome._url.path.includes('SASLogon')) {
            connSpinner.succeed(`Viya Server ${chalk.greenBright('found!')}`);
        } else {
            // something else happened
            connSpinner.fail(`Viya Server ${chalk.redBright('not found!')}`);
            configurationResult = 'Viya Server not found';
        }
        
        const msSpinner = ora('Checking for microservices:').start();
        // If we're on Viya then we have microservices to look for
        let sucMs = []
        let failMs = []
        for (const item of msList)
        {
            msSpinner.text = `Checking for Microservice: ${chalk.blue(item.msName)}`;
            let identOutcome = await checkSasServer(promptRes.sasLocation + item.msLoc);
            if (identOutcome._url && identOutcome._url.path && identOutcome._url.path.includes('SASLogon')) {
                // found SASLogon in the redirect URI, this is good enough for basic validation
                sucMs.push(item)
            } else {
                // something else happened
                failMs.push(item)
            }
        }
        if (failMs.length === 0) {
            msSpinner.succeed(`All microservices ${chalk.greenBright('found!')}`);
        } else {
            msSpinner.fail(`At least some microservices were ${chalk.redBright('not found!')}`);
            configurationResult = 'Some microservices are not available.';
        }
        
    }
    if (promptRes.sasType === 'v9') {
        // root of v9 we expect an apache greeter 
        if (basicOutcome._url && basicOutcome._url.path && basicOutcome.responseText.includes('SAS')) {
            // found SAS as the text in the response. For v9 this is our basic validation
            connSpinner.succeed(`SAS v9 Web Server ${chalk.greenBright('found!')}`);
        } else {
            // something else happened
            connSpinner.fail(`SAS v9 Web Server ${chalk.redBright('not found!')}`);
            configurationResult = 'SAS v9 Web Server is not available.';
        }
        
        stpSpinner = ora(`Checking for Application: ${chalk.blue('SASStoredProcess')}`);
        let stpOutcome = await checkSasServer(promptRes.sasLocation + '/SASStoredProcess');
        if (stpOutcome._url && stpOutcome._url.path && stpOutcome._url.path.includes('SASLogon')) {
            stpSpinner.succeed(`SAS Stored Process Web App ${chalk.greenBright('found!')}`);
        } else {
            // something else happened
            stpSpinner.fail(`SAS Stored Process Web App ${chalk.redBright('not found!')}`);
            configurationResult = 'SAS Stored Process Web App is not available.';
        }
    }
    
    if (configurationResult  === 'Ok') {
        // parse settings and write  to .env file
        var serverUrl = new URL(promptRes.sasLocation)
        if (serverUrl.protocol === 'https:') {
            templateHttps = 'HTTPS=true\n' 
        } else {
            templateHttps = ''
        } 
        var templateHost = serverUrl.hostname
        fs.writeFileSync('./.env', `${templateHttps}SASHOST=${templateHost}\nSASVER=${promptRes.sasType}`)
        
        log(`\nConfiguration ${chalk.greenBright('successful!')} Variables written to ${chalk.hex('#FAAD39')('.env')} file in project root.\nFrom now, start the app in Development mode by runing: \n\n  ${chalk.hex('#FAAD39')('yarn start')} \n`);
        process.exit(0);
    } else {
        log(`\nConfiguration ${chalk.redBright('not successful!')}. Try again.`);
        process.exit(0);
    }
    
}

configureSas()
