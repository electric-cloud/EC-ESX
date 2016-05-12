/*
   Copyright 2015 Electric Cloud, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package test.java.ecplugins.esx;

public enum ProcedureNames {

	LIST_ENTITY("ListEntity"),
	LIST_SNAPSHOT("ListSnapshot"),
	LIST_DEVICE("ListDevice"),
	CREATE_FOLDER("CreateFolder"),
	CREATE_RESOURCEPOOL("CreateResourcepool"),
	ADD_CDDVD_DRIVE("AddCdDvdDrive"),
	ADD_NW_INTERFACE("AddNetworkInterface"),
	ADD_HARDDISK("AddHardDisk"),
	RENAME_ENTITY("RenameEntity"),
	MOVE_ENTITY("MoveEntity"),
	EDIT_RESOURCEPOOL("EditResourcepool"),
	EDIT_CDDVD_DRIVE("EditCdDvdDrive"),
	DISPLAY_ESX_SUMMARY("DisplayESXSummary"),
	EXPORT("Export"),
	REVERT_TO_CURR_SNAPSHOT("RevertToCurrentSnapshot"),
	REMOVE_SNAPSHOT("RemoveSnapshot"),
	REMOVE_DEVICE("RemoveDevice"),
	DELETE_ENTITY("DeleteEntity");
	
	
	private String procedureName;

	private ProcedureNames(String procedureName) {
		this.procedureName = procedureName;
	}

	public String getProcedureName() {
		return procedureName;
	}
	
	
}
