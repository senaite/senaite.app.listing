import React from "react";
import ColumnFilterRow from "./ColumnFilterRow.js";
import TableHeaderRow from "./TableHeaderRow.js";
import TableRows from "./TableRows.coffee";


class Table extends React.Component {

  constructor(props) {
    super(props);
  }

  render() {
    return (
      <table id={this.props.id} className={this.props.className}>
        <thead>
          <TableHeaderRow {...this.props} />
          <ColumnFilterRow {...this.props} />
        </thead>
        <tbody>
          <TableRows {...this.props} />
        </tbody>
      </table>
    );
  }
}


export default Table;
