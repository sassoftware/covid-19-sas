import constants from '../../config/constants'

export const datepickerProps = {
 datePickerType: "single",
 dateFormat: "Y/d/m"
}
export const datePickerInput = {
 labelText: 'DataPicker input Label',
 // pattern: 'd{1,2}/d{4}',
 placeholder: constants.DATE_FORMAT,
 disabled: false,
 invalid: false,
 invalidText: 'A valid value is required',
 iconDescription: 'Icon description',
 // onClick: (e) => {            // default listenters commented out
 //   console.log('onClic', e.target)
 // },
 // onChange: (e) => {
 //   console.log('onChage', e.target)
 // },
}