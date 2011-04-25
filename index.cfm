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
	<cfinclude template="plugin/config.cfm" />
	
	<!--- HTML class/ID namespace --->
	<cfset ns = 'br-vm-' />
	<cfparam name="url.voteStatus" default="">
	<!--- voting dao --->
	<cfset dao = createObject( "component", "plugins.#pluginConfig.getDirectory()#.lib.votingDAO" ).init() />

	<!--- get voting portals --->
	<cfset votingPortals = dao.getAllVotingPortals() />

	<!--- get all voting portals --->
	<!---
	<cfquery name="votingPortals" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
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
			and tcontent1.type = 'Portal'
			and tcontent1.subType = 'Voting'	
		ORDER BY
			pageCnt
	</cfquery>
	--->

	<cfsavecontent variable="body">
	<cfoutput>
	<h2>#pluginConfig.getName()#</h2>
	<h3>List of voting pages</h3>

	<!--- get headers --->
	<cfset headerList = pluginConfig.getSetting( "displayableGroupsByStatus" ) />
	<!--- header --->
	<cfoutput>
		<div id="#ns#votingGroups">
		Group by: [ <a href="#application.configBean.getContext()#/plugins/#pluginConfig.getDirectory()#/">All</a> ]
		 <!---[ <a href="#application.configBean.getContext()#/plugins/#pluginConfig.getDirectory()#/?accepted=true">Accepted</a> ]--->
		<cfloop list="#headerList#" delimiters="^" index="header">
			[ <a href="#application.configBean.getContext()#/plugins/#pluginConfig.getDirectory()#/?voteStatus=#urlEncodedFormat(header)#">#HTMLEditFormat(header)#</a> ]
		</cfloop>
		</div>
	</cfoutput>
	<br />

	<cfif votingPortals.recordcount>
	<!--- loop over protals --->
	<cfloop query="votingPortals">
		
		<!--- get voting page details --->
		<cfset votingPageDetails = dao.getVotingPortalPages(
			siteId: session.siteId,
			parentId: votingPortals.contentId,
			type: 'Page',
			subType: 'Voting',
			voteStatus=url.voteStatus
					
		) />
		<!---
		<!--- get voting page details --->
		<cfquery name="votingPageDetails" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
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
			WHERE
				tcontent1.active = 1
				and tcontent1.siteId = '#session.siteid#'
				and tcontent1.parentid = '#votingPortals.contentid#'
				and tcontent1.type = 'Page'
				and tcontent1.subType = 'Voting'	
			ORDER BY
				voteCnt desc
		</cfquery>
		--->
		
		<h3>Portal: #votingPortals.Title# (#votingPortals.pageCnt# voting pages found)</h3>
		<table class="stripe">
			<tr>
				<th>Title</th>
				<th>Site Id</th>
				<th>Status</th>
				<th>Votes</th>
			</tr>
			<cfif votingPageDetails.hasNext()>
			<cfloop condition="votingPageDetails.hasNext()">
				
				<!--- get content bean --->
				<cfset contentBean =votingPageDetails.next() />
				
				<!--- render content --->
				<tr>
					<td><a href="#contentBean.getURL()#">#HTMLEditFormat(contentBean.getTitle())#</a></td>
					<td>#contentBean.getSiteId()#</td>
					<td>#contentBean.getValue( "voteStatus" )#</td>
					<td>#contentBean.getvoteCnt()#</td>
				</tr>
				
			</cfloop>
			<cfelse>
				<tr>
					<td colspan="4" calss="noresults">
					<cfif len(url.voteStatus)>
					This portal current has not items set to "#HTMLEditFormat(url.voteStatus)#".
					<cfelse>
					This portal contains no items.
					</cfif>
					</td>
				</tr>
			</cfif>
			</tr>
		</table>
	</cfloop>
	<cfelse>
		<p>There are currently no Portals with a sub-type of "Voting" created.</p>
	</cfif>
	</cfoutput>
	</cfsavecontent>

	<cfoutput>
	#application.pluginManager.renderAdminTemplate(body=body,pageTitle=pluginConfig.getName())#
	</cfoutput>

