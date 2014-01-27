<!---
   Copyright 2011 Blue River Interactive

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--->
<cfcomponent output="false" extends="mura.cfobject">
 
	<cffunction name="saveSuggestion" access="public" returntype="any" output="false">
		<cfargument name="title" type="string" required="true" />
		<cfargument name="userId" type="string" required="true" />
		<cfargument name="suggestion" type="string" required="true" />
		<cfargument name="parentId" type="string" required="true" />
		<cfargument name="approved" type="string" required="true" />
		<cfargument name="siteid" type="string" required="true" />
		
		<cfset var content=application.contentManager.getActiveContent( '' , arguments.siteid ) />
		
		<cfset content.setParentID( arguments.parentId ) />
		<cfset content.setType("Page") />
		<cfset content.setSubType("Voting") />
		<cfset content.setTitle( arguments.title ) />
		<cfset content.setBody( arguments.suggestion ) />
		<!--- if approved is passed --->
		<cfif len( arguments.approved ) AND arguments.approved>
			<cfset content.setApproved( 1 ) />
		<cfelse>
			<cfset content.setApproved( 0 ) />
			<cfset content.setDisplay( 0 ) />
		</cfif>
		<!---
		<cfset content.setValue( "extendSetID", application.classExtensionManager.getSubTypeByName( "Page", "Voting", arguments.siteid ).getExtendSetByName( "Default" ).getExtendSetID() ) />
		--->
		<cfset content.setValue( "voteStatus", "Open" ) />
		<!--- add content to db --->
		<cfset content.save() />
		
		<cfreturn content />
	</cffunction>
	
	<cffunction name="getAllVotingFolders" access="public" returntype="query" output="false">
	
		<cfset votingFolders = "" />
	
		<!--- get all voting protals --->
		<cfquery name="votingFolders" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
			SELECT
				*,
				(
					SELECT
						COUNT( contentId )
					FROM
						tcontent tcontent2
					WHERE
						ParentID = tcontent1.contentId
						AND active = 1
						AND type = 'Page'
						AND subType = 'Voting'
				) AS pageCnt
			FROM
				tcontent tcontent1
			WHERE
				tcontent1.active = 1
				and tcontent1.approved = 1
				and tcontent1.type = 'Folder'
				and tcontent1.subType = 'Voting'	
			ORDER BY
				pageCnt
		</cfquery>
	
		<cfreturn votingFolders />
	</cffunction>
	
	<cffunction name="getVotingFolderPages" access="public" returntype="any" output="false">
		<cfargument name="siteId" type="string" required="true" />
		<cfargument name="parentId" type="string" required="true" />
		<cfargument name="voteStatus" type="string" required="false" />
		<cfargument name="searchPhrase" type="string" required="false"/>
	
		<cfset var rs = "" />

		<!--- get voting page details --->
		<cfquery name="rs" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
			SELECT
				*,
				(
					SELECT
						SUM( rate )
					FROM 
						tcontent tcontent2
						INNER JOIN tcontentratings on (tcontentratings.contentID=tcontent2.contentID and tcontentratings.siteID=tcontent2.siteID) 
					WHERE 
						tcontent2.active=1
						AND tcontentratings.contentid=tcontent1.contentid
				) AS voteCnt
			FROM
				tcontent tcontent1
				
				<!--- join up to the attributes table if certain params are passed --->
				<cfif ( isDefined( "arguments.voteStatus" ) AND arguments.voteStatus IS NOT "" )>
					left join tclassextenddata 
						inner join tclassextendattributes on tclassextendattributes.attributeID = tclassextenddata.attributeID 
					on (tclassextenddata.baseID=tcontent1.contentHistId)
				</cfif>
				
			WHERE
				tcontent1.active = 1
				and tcontent1.approved = 1
				and tcontent1.siteId = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#" />
				and tcontent1.parentid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.parentid#" />
				and tcontent1.type = 'Page'
				and tcontent1.subType = 'Voting'	
				
				<!--- filter off of group --->
				<cfif isDefined( "arguments.voteStatus" ) AND arguments.voteStatus IS NOT "">
					and tclassextendattributes.name like 'voteStatus'
					and tclassextenddata.attributeValue like <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.voteStatus#" />
				</cfif>
				
				<!--- filter by accepted 
				<cfif isDefined( "arguments.accepted" ) AND arguments.accepted>
					and tclassextendattributes.name like 'voteAccepted'
					and tclassextenddata.attributeValue like 'Yes'
				</cfif>
				--->
				<!--- filter by search phrase --->
				<cfif isDefined( "arguments.searchPhrase" ) AND arguments.searchPhrase IS NOT "">
					and 
						(
							tcontent1.title like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.searchPhrase#%" />
							or
							tcontent1.body like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.searchPhrase#%" />
						)
				</cfif>
				
			ORDER BY
				voteCnt desc
		</cfquery>
		
		<cfreturn getBean("contentIterator").setQuery(rs) />
	</cffunction>
	
	<cffunction name="getVoteCount" access="public" returntype="query" output="false">
		<cfargument name="type" type="string" required="false" />
		<cfargument name="subType" type="string" required="false" />
		<cfargument name="userId" type="string" required="false" />
		<cfargument name="contentId" type="string" required="false" />
		<cfargument name="attributeName" type="string" required="false" />
		<cfargument name="attributeValue" type="string" required="false" />
	
		<cfset var voteSum = "" />
	
		<cfquery name="voteSum" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
			select 
				sum(rate) AS total 
			from 
				tcontent
				inner join tcontentratings on (tcontentratings.contentID=tcontent.contentID and tcontentratings.siteID=tcontent.siteID) 
				
				<cfif isDefined( "arguments.attributeName" ) OR isDefined( "arguments.attributeValue" )>
					left join tclassextenddata 
						inner join tclassextendattributes on tclassextendattributes.attributeID = tclassextenddata.attributeID 
					on (tclassextenddata.baseID=tcontent.contentHistId)
				</cfif>
			where 
				tcontent.active=1
				and tcontent.approved = 1
				
				<cfif isDefined( "arguments.type" )>
					and tcontent.type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.type#" /> 
				</cfif>
				
				<cfif isDefined( "arguments.subType" )>
					and tcontent.subType=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.subType#" /> 
				</cfif>
				
				<cfif isDefined( "arguments.userId" )>
					and tcontentratings.userid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userid#" /> 
				</cfif>
				
				<cfif isDefined( "arguments.contentId" )>
					and tcontentratings.contentid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentid#" /> 
				</cfif>
				
				<cfif isDefined( "arguments.attributeName" )>
					and tclassextendattributes.name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.attributeName#" /> 
				</cfif> 
				
				<cfif isDefined( "arguments.attributeValue" )>
					and tclassextenddata.attributeValue like <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.attributeValue#" /> 
				</cfif>
				
				<!--- and tcontent.path like '%[probably a folder with a target subtype]%' --->
		</cfquery>
		
		<cfreturn voteSum />
	</cffunction>
	
	<!---
	<cffunction name="getVotingCategoriesByList" access="public" returntype="query" output="false">
		<cfargument name="categoryList" type="string" required="true" />
		<cfargument name="delimiters" type="string" required="false" default="^" />
	
		<cfset var rs = "" />
		<cfset var category = "" />
		
		<cfquery name="voteSum" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
			select 
				DISTINCT tclassextenddata.attributeValue as category,
				count( * ) as cnt
			from 
				tcontent
				left join tclassextenddata 
					inner join tclassextendattributes on tclassextendattributes.attributeID = tclassextenddata.attributeID 
				on (tclassextenddata.baseID=tcontent.contentHistId)
			where 
				tcontent.active=1
				
				and tclassextendattributes.name like 'Status'
				
				<cfloop list="#arguments.categoryList#" index="category" delimiters="#arguments.delimiters#">
					and tclassextenddata.attributeValue like <cfqueryparam cfsqltype="cf_sql_varchar" value="#category#" /> 
				</cfloop>
			group by 
				tclassextenddata.attributeValue
		</cfquery>
		
		<cfreturn rs />
	</cffunction>
	--->
	
</cfcomponent>