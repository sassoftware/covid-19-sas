import React from 'react'
import './badge.scss'

const Badge = (props) => {
  const {value, background, width, height, color} = props;
  return(
  <div className={'badge'} style={{
    backgroundColor: background,
    width: width,
    height: height,
    color: color
  }}>
    <span>{value}</span>
  </div>
  )
}


export default Badge;
