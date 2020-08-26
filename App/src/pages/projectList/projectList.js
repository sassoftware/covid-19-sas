import React, {useEffect, useState} from 'react'
import {
	DataTable,
	TableContainer,
	Table,
	TableRow,
	TableHead,
	TableHeader,
	TableBody,
	TableCell,
	Search,
	Loading,
	Pagination
} from 'carbon-components-react'
import "./projectList.scss";
import {fetchProjects} from './projectListActions';
import {useDispatch, useSelector} from 'react-redux';
import {useHistory} from 'react-router';
import moment from 'moment'

const headerData = [
	{
		header: "Name",
		key: "name",
	},
	{
		header: "Created by",
		key: "createdBy",
	},
	{
		header: "Creation Date",
		key: "creationTimeStamp",
	},
	{
		header: "Modified by",
		key: "modifiedBy",
	}
];


export const ProjectList = () => {

	const dispatch = useDispatch();
	const history = useHistory();

	const [search, setSearch] = useState('');
	const [paginationPage, setPaginationPage] = useState(1)
	const [paginationPageSize, setPaginationPageSize] = useState(10)

	const projects = useSelector(state => state.projectList.projects)
	const spinner = useSelector(state => state.projectList.mainSpinner)

	const filtered = projects.filter(el => {
		return el.name.toLowerCase().includes(search.toLocaleLowerCase()) || search === ''
	})

	const tableTitle = () => {
		return (
			<div className="flex flex-row justify-content-between align-items-center">
				<h4>Project List</h4>
				<Search
					labelText="search"
					value={search}
					onChange={(e) => setSearch(e.target.value)}
					id="search-1"
					placeHolderText="Filter by name"
				/>
			</div>
		)
	}

	const submitRequest = (id) => {
		const project = projects.find(p => p.id === id)
		if (project) {
			let uri = project.uri.split('/').pop()
			history.push(`/project/${uri}`);
		}
	}

	const handlePaginationChange = e => {
		setPaginationPage(e.page);
		setPaginationPageSize(e.pageSize);
	};

	const getCurrentPageRows = rows => {
		let lastItemIndex = 0;

		if (paginationPage === 1 || rows.length <= paginationPageSize) {
			lastItemIndex = paginationPageSize;
		} else {
			lastItemIndex = paginationPageSize * paginationPage;
		}
		return rows.slice((paginationPage - 1) * paginationPageSize, lastItemIndex);
	};

	useEffect(() => {
		fetchProjects(dispatch);
		return () => {

		}
	}, [dispatch])

	return (
		<div className={'align-center'}>
			<DataTable
				isSortable={true}
				rows={filtered}
				headers={headerData}
				render={({rows, headers, getHeaderProps}) => {
					let currentPageRows = getCurrentPageRows(rows);
					return (
						<TableContainer title={tableTitle()}>
							<Table size='tall'>
								<TableHead>
									<TableRow>
										{headers.map(header => (
											<TableHeader {...getHeaderProps({header})}>
												{header.header}
											</TableHeader>
										))}
									</TableRow>
								</TableHead>
								{
									! spinner &&
									<TableBody>
										{currentPageRows.map(row => {
											return (
												<TableRow key={row.id} onClick={() => submitRequest(row.id)}>
													{row.cells.map((cell, i) => (
														<TableCell key={cell.id}>{i !== 2 ? cell.value : moment(cell.value).format('MMM DD YYYY HH:mm')}</TableCell>
													))}
												</TableRow>
											)
										})}
									</TableBody>
								}
							</Table>
						</TableContainer>)
				}
				}
			/>
			{! spinner ?
				<Pagination
					pageSizes={[10, 20, 30, 40, 50]}
					totalItems={filtered.length}
					itemsPerPageText={'Projects per page'}
					onChange={handlePaginationChange}
				/>
				:
				<Loading description="Active loading indicator" withOverlay={false}/>
			}
		</div>
	)
}

