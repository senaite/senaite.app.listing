import React from "react"

import "./Loader.css"

# The corners of a cell: the hexagon of the SENAITE logo, point up
CELL = "10,1 19,6 19,16 10,21 1,16 1,6"


###*
 * Three cells of the hexagon of the SENAITE logo that light up one after
 * the other while the listing loads
###
class Loader extends React.Component

  render_cell: (index) ->
    <svg key={index} viewBox="0 0 20 22">
      <polygon points={CELL}></polygon>
    </svg>

  render: ->
    if not @props.loading
      # render a placeholder to avoid vertical jumps
      return <div className="loader"></div>

    <div className="loader" role="status">
      {[0, 1, 2].map (index) => @render_cell index}
    </div>


export default Loader
