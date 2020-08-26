import React from 'react'

const errorPage = (error) => {
	const {status = '404', message = 'Page not found, keep looking!'} = error
	return <div>
		<h4>Error</h4>
		{status && <div className={'text-danger'}>Status: {status}</div>}
		{message && <div className={'text-danger'}>Message: {message}</div>}
	</div>
}

export default errorPage
