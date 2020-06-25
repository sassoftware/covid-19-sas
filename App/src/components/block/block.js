import React from 'react'
import './block.scss'

export const Block = (props) => {
	const title = props.title || 'Noname'
	const number = props.number || 0
	const description = props.description || 'Default description'
	const backgroundColor = props.backgroundColor || 'white'
	const borderBottomColor = props.borderBottomColor || 'black'
	const textColor = props.textColor || '#565656'

	return (
		<div
			className={'block'}
			style={{backgroundColor, color: textColor, borderBottomColor}}>
			<div className={'blockTitle'}>
				{title}
			</div>
			<div>
				<span className={'number'}>{number}</span>
			</div>
			<div>
				<span className={'desc'}>{description}</span>
			</div>
		</div>
	)
}
