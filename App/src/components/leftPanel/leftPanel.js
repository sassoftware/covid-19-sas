import React, {useEffect, useState} from 'react'
import {SideNav, SideNavItems, SideNavMenu, SideNavLink} from 'carbon-components-react'
import './leftPanel.scss';
import {
	Settings16,
	Home16,
	Application16,
	Edit32,
	Restart32,
	Folder32,
	Add16
} from '@carbon/icons-react';
import {useHistory} from 'react-router-dom'
import {useSelector} from 'react-redux';
import Save from '../save/save'

const logs = ['/applicationLogs', '/errorLogs', '/failedRequests', '/debugLogs'];

export const LeftPanel = (props) => {
	const history = useHistory();
	const [showActions, setShowActions] = useState(false);
	const {projectContent, projectMetadata} = useSelector(state => state.project)
	const projectUri = projectMetadata && projectMetadata.uri.split('/').pop()
	const scenarioName = history.location.pathname.split('/').pop()

	const resizeHandle = () => {
		// At this width carbon hides its navigation bar
		if (window.window.innerWidth < 1056) {
			setShowActions(true);
		}
		else {
			setShowActions(false);
		}
	}

	const routing = () => {
		if (logs.includes(history.location.pathname)) {
			history.replace('/')
		}
		else {
			history.push('/')
		}

	}

	useEffect(() => {
		resizeHandle();
		window.addEventListener('resize', resizeHandle)
		return () => {
			window.removeEventListener('resize', resizeHandle)
		}
	}, [])
	return (
		<SideNav isFixedNav aria-label="Side navigation" expanded={props.toglePanel}>
			<SideNavItems className={'sideItems'}>
				{
					showActions ? <SideNavItems className={'sideActions'}>
							<SideNavLink onClick={props.newProject} title="Add new project">
								<Edit32/>
							</SideNavLink>
							<SideNavLink>
								<Restart32/>
							</SideNavLink>
							<SideNavLink onClick={() => history.push('/projectList')}>
								<Folder32/>
							</SideNavLink>
							<SideNavLink>
								<Save color={"black"}/>
							</SideNavLink>
						</SideNavItems>


						: null
				}
				<SideNavLink onClick={routing} renderIcon={Home16}>Home</SideNavLink>
				<SideNavLink renderIcon={Application16} onClick={() => history.push('/project/'+projectUri)}>Project
					properties</SideNavLink>
				<SideNavMenu
					renderIcon={Settings16}
					title="Saved Scenarios"
					defaultExpanded={true}
				>
					{projectContent !== null && projectContent.savedScenarios.map((configuration, i) =>
						<SideNavLink
							isActive={configuration.scenario === scenarioName}
							key={i + configuration.scenario}
							onClick={() => {
								history.push(`/project/${projectUri}/scenario/${configuration.scenario}`)
							}}
						>
							{configuration.scenario}
						</SideNavLink>
					)
					}
					<SideNavLink onClick={props.openDataConfDialog}>
						<div className={'flex align-items-center'}><Add16/> Add new</div>
					</SideNavLink>
					{/* <ToastNotification kind="error" title="Error"
                        subtitle={<span>You must first select a project</span>}/> */}
				</SideNavMenu>


			</SideNavItems>
		</SideNav>
	)
}



