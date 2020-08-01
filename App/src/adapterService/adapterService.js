// import H54s from '../h54s/src/h54s'
import H54s from 'h54s'
import Utils from 'h54s/src/methods/utils'
import ADAPTER_SETTINGS from './config'
import {setShouldLogin} from '../components/loginModal/loginModalActions'
import {setRequest} from './adapterActions'
import toastr from 'toastr'
import { getSelfUriFromLinks } from '../components/utils'
import { PROJECT_EXTENTION } from '../components/newProject/newProjectActions'

toastr.options.progressBar = true;

class adapterService {
	constructor() {
		this.requests = new Map();
		this.shouldLogin = true;
		this._adapter = new H54s(ADAPTER_SETTINGS);
		// setting it here to invoke setter method
		this.setDebugMode(localStorage.getItem('debugMode') || false)
	}

	_callback(err, res, resolve, reject, dispatch) {
		if (err) {
			if (err.type === 'notLoggedinError') {
				setShouldLogin(dispatch, true)
			} else if (!!err) {
				return reject(err);
			}
		} else if (!err && res) {
			this.handleUserMessage(res)
			return resolve(res)
		}
	}

	_handleRequest(dispatch, promise, program) {
		setRequest(dispatch, promise, {
			program,
			running: true,
			successful: undefined
		})

		promise.then(() => {
			setRequest(dispatch, promise, {
				running: false,
				successful: true,
				timestamp: new Date()

			})
		}).catch(() => {
			setRequest(dispatch, promise, {
				running: false,
				successful: false,
				timestamp: new Date()
			})
		});
	}

	login(dispatch, user, pass) {
		return new Promise((resolve, reject) => {
			// Handle login on different versions of SAS
			if (ADAPTER_SETTINGS.sasVersion === 'v9') {
				this._adapter.login(user, pass, (status) => {
					if (status === 200 || status === 449) {
						// this.shouldLogin.next(false);
						setShouldLogin(dispatch, false)
						resolve(status);
					}
					let errorMessage = 'There was a problem.'
					if (status === -1) {
						errorMessage = 'Username or password invalid'
						reject(errorMessage)
					} else if (status === -2) {
						errorMessage = 'Problem communicating with server'
						reject(errorMessage)
					} else {
						reject(errorMessage)
					}
				})
			} else {
				this._adapter.promiseLogin(user, pass)
					.then(status => {
						if (status === 200 || status === 449) {
							// this.shouldLogin.next(false);
							setShouldLogin(dispatch, false)
							resolve(status);
						}
						let errorMessage = 'There was a problem.'
						if (status === -1) {
							errorMessage = 'Username or password invalid'
							reject(errorMessage)
						} else if (status === -2) {
							errorMessage = 'Problem communicating with server'
							reject(errorMessage)
						} else {
							reject(errorMessage)
						}
					})
					.catch(e => {
						let errorMessage = 'There was a problem.'
						if (e === 401) {
							errorMessage = 'Username or password invalid'
						}
						console.log(errorMessage)
						reject(errorMessage)
					})
			}
		});
	}


	/*
	@dispatch - redux store management part
	@method - can be get, post and put
	@url - viya API endpoint
	@options - {useMultipartFormData, sasProgram, dataObj, params, callback, headers}
	 */
	managedRequest(dispatch, method, url, options) {
		// Set useMultipartFormData to true if not provided
		const _options = {
			useMultipartFormData: true,
			...options // spraed passed options
		}
		const promise = new Promise((resolve, reject) => {
			this._adapter.managedRequest(method, url, {
				// default callback if there is no provided one as a parameter
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			})
		})

		// In header is tracker of requests, this is where it is handled
		this._handleRequest(dispatch, promise, url)

		return promise
	}


	// Function that directly invoke SAS program call
	call(dispatch, program, tables) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.call(program, tables, (err, res) => this._callback(err, res, resolve, reject, dispatch));
		});

		this._handleRequest(dispatch, promise, program)

		return promise
	}

	logout() {
		return new Promise((resolve, reject) => {
			this._adapter.logout((errStatus) => {
				if (errStatus !== undefined) {
					reject(new Error(`Logout failed with status code ${errStatus}`));
				} else {
					resolve();
				}
			});
		});
	}

	createTable(rows, name) {
		return new H54s.SasData(rows, name);
	}

	getDebugMode() {
		return this._debugMode;
	}

	setDebugMode(debugMode) {
		localStorage.setItem("debugMode", debugMode);
		this._debugMode = this._adapter.debug = debugMode;
	}

	getObjOfTable(table, key, value) {
		return Utils.getObjOfTable(table, key, value)
	}

	handleUserMessage(res) {
		if (res.usermessage && res.usermessage !== 'blank') {
			toastr.info(res.usermessage)
		}
	}

	fromSasDateTime(time) {
		return Utils.fromSasDateTime(time)
	}



	getFolderDetails(dispatch, folderName, _options = {}) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.getFolderDetails(folderName, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			});
		});
		this._handleRequest(dispatch, promise, 'Get details for '+folderName)
		return promise
	}

	getFileDetails(dispatch, fileUri, _options = {}) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.getFileDetails(fileUri, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			});
		});
		this._handleRequest(dispatch, promise, 'Get '+fileUri)
		return promise
	}

	getFileContent(dispatch, fileUri, _options = {}) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.getFileContent(fileUri, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			});
		});
		this._handleRequest(dispatch, promise, 'Get conten for '+fileUri)
		return promise
	}

	getFolderContents(dispatch, folderName, _options = {}) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.getFolderContents(folderName, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			});
		});
		this._handleRequest(dispatch, promise, 'Get content of '+folderName)
		return promise
	}
	createNewFolder(dispatch, parentUri, folderName, _options = {}) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.createNewFolder(parentUri, folderName, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			});
		});
		this._handleRequest(dispatch, promise, 'Create '+folderName)
		return promise
	}

	createNewFile(dispatch, fleName, fileBlob, parentUri, _options = {}) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.createNewFile(fleName, fileBlob, parentUri, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			});
		});
		this._handleRequest(dispatch, promise, 'Create ' + fleName)
		return promise
	}


	createNewFileToFolderPath(dispatch, fleName, fileBlob, folderName, _options = {}) {

		const promise = new Promise(async (resolve, reject) => {
			const res = await this.getFolderDetails(dispatch, folderName)
			const parentFolderUri = '/folders/folders/'+res.body.id
			// debugger
			// console.log(res)
			this._adapter.createNewFile(fleName, fileBlob, parentFolderUri, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch),
				..._options
			});
		});
		this._handleRequest(dispatch, promise, 'Create ' + fleName)
		return promise
	}

	deleteItem(dispatch, itemUri) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.deleteItem(itemUri, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch)
			});
		});
		this._handleRequest(dispatch, promise, 'Delete ' + itemUri)
		return promise
	}

	updateFile(dispatch, itemUri, dataObj, lastModified) {
		const promise = new Promise((resolve, reject) => {
			this._adapter.updateFile(itemUri, dataObj, lastModified, {
				callback: (err, res) => this._callback(err, res, resolve, reject, dispatch)
			});
		});
		this._handleRequest(dispatch, promise, 'Update ' + itemUri)
		return promise
  }

  async getAllProjects(dispatch) {

    let url = "/folders/folders/@item?path=" + ADAPTER_SETTINGS.metadataRoot;
    let res = await this.managedRequest(dispatch, 'get', url, {});
    const afiUrl = getSelfUriFromLinks(res.body)
    if (afiUrl !== '') {
      let url = afiUrl + "/members?filter=and(eq('contentType', 'file'),endsWith('name','" + PROJECT_EXTENTION + "'))&limit=10000";
      res = await this.managedRequest(dispatch, 'get', url, {});
    }

    return res.body.items;
  }
  
  getProject(dispatch, projectUri) {
    if (!projectUri.includes('/files/files')) projectUri = '/files/files/' + projectUri;

    const allprojects = this.getAllProjects(dispatch,  projectUri);

    return allprojects.then(projects => {

      const content = this.getFileContent(dispatch, projectUri);

      return content.then(contentRes => {
        const metadata = projects.find(p => (p.uri === projectUri))
        if(!metadata) {
          return {projectContent: null, projectMetadata: null}
        }
        const projectContent = Object.assign({}, contentRes.body, 
          {lastModified: contentRes.headers['last-modified'] || contentRes.headers.get('Last-Modified')});
        const projectMetadata = Object.assign({}, metadata, 
          {uri: projectUri})
        return {
          projectMetadata, projectContent
        }
      })
    })
  }
}

export default new adapterService()
