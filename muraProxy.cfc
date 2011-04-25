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
	<cfcomponent>

		<cfset variables.pluginConfig = application.pluginManager.getConfig( "muravoice" ) />
		<cfset variables.json = createObject( "component", "mura.json" ) />
		<cfset variables.dao = createObject( "component", "#pluginConfig.getPackage()#.lib.votingDAO").init() />

		<!--- ****************************** --->
		<!--- CONSTRUCTOR/ACCESS METHODS --->
		<!--- CONFIGURE METHODS --->
		<!--- ****************************** --->
		<cffunction name="init" access="public" returntype="any" output="false">
			<cfreturn this />
		</cffunction>

		<cffunction name="remote" access="remote" returntype="any" output="false">
			<cfargument name="process" type="string" required="true" />
			<cfargument name="siteId" type="string" required="true" />
			<cfargument name="userId" type="string" required="true" />
			
			<cfset var results = "" />
			<cfset var $ = application.serviceFactory.getBean("MuraScope").init(arguments.siteID)>
			<!--- security check --->
			<!--- make sure the user is logged in --->
			<cfif NOT $.currentUser().isLoggedIn()>
				<cfabort />
			</cfif>
			
			<!--- run configure command --->
			<cfset configure() />
			
			<!--- invoke the called method --->
			<cfinvoke component="#this#" method="#arguments.process#" argumentcollection="#arguments#" returnvariable="results" />
			
			<cfif isDefined( "results" )>
				<cfreturn results>
			</cfif>
			
		</cffunction>
		
		<cffunction name="configure" access="public" returntype="void" output="false">
			
		</cffunction>

		<!--- ****************************** --->
		<!--- DATA GATHERING/RENDERING METHODS --->
		<!--- ****************************** --->
		<cffunction name="getCurrentUserOverallVoteCount" access="public" returntype="any" output="false">
			<cfargument name="userId" type="string" required="true" />
			<cfargument name="siteId" type="string" required="true" />
			
			<cfset var voteSum = "" />
			<cfset var results = 0 />
			
			<!--- get vote sum --->
			<cfset voteSum = variables.dao.getVoteCount( 
				type: 'Page',
				subType: 'Voting',
				userId: arguments.userid,
				attributeName: 'voteStatus',
				attributeValue: 'Open'
			) />
			<!---
			<cfquery name="voteSum" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
				select 
					sum(rate) AS total 
				from 
					tcontent
					inner join tcontentratings on (tcontentratings.contentID=tcontent.contentID and tcontentratings.siteID=tcontent.siteID) 
					left join tclassextenddata 
						inner join tclassextendattributes on tclassextendattributes.attributeID = tclassextenddata.attributeID 
					on (tclassextenddata.baseID=tcontent.contentHistId)
				where 
					tcontent.active=1
					and tcontent.type='Page' 
					and tcontent.subType='Voting' 
					and tcontentratings.userid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userid#" /> 
					and tclassextendattributes.name='Status' 
					and tclassextenddata.attributeValue like '%Open%' 
					
					<!--- and tcontent.path like '%[probably a portal with a target subtype]%' --->
			</cfquery>
			--->
			
			<!--- get recordcount if total is no blank --->
			<cfif trim( voteSum.total ) IS NOT "">
				<cfset results = voteSum.total />
			</cfif>

			<cfreturn results />
		</cffunction>
		
		<cffunction name="getCurrentUserPageVoteCount" access="public" returntype="numeric" output="false">
			<cfargument name="userId" type="string" required="true" />
			<cfargument name="contentId" type="string" required="true" />
			
			<cfset var voteSum = "" />
			<cfset var results = 0 />
			
			<!--- get vote sum --->
			<cfset voteSum = variables.dao.getVoteCount( 
				type: 'Page',
				subType: 'Voting',
				userId: arguments.userid,
				contentId: arguments.contentId
			) />
			<!---
			<cfquery name="voteSum" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
				select 
					sum(rate) AS total 
				from 
					tcontent
					inner join tcontentratings on (tcontentratings.contentID=tcontent.contentID and tcontentratings.siteID=tcontent.siteID) 
				where 
					tcontent.active=1
					and tcontent.type='Page' 
					and tcontent.subType='Voting' 
					and tcontentratings.contentid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentid#" />
					and tcontentratings.userid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userid#" /> 

					<!--- and tcontent.path like '%[probably a portal with a target subtype]%' --->
			</cfquery>
			--->

			<!--- get recordcount if total is no blank --->
			<cfif trim( voteSum.total ) IS NOT "">
				<cfset results = voteSum.total />
			</cfif>

			<cfreturn results />
		</cffunction>
		
		<cffunction name="getPageVoteCount" access="public" returntype="numeric" output="false">
			<cfargument name="siteId" type="string" required="true" />
			<cfargument name="contentId" type="string" required="true" />
			
			<cfset var voteSum = "" />
			<cfset var results = 0 />
			
			<!--- get vote sum --->
			<cfset voteSum = variables.dao.getVoteCount( 
				type: 'Page',
				subType: 'Voting',
				siteId: arguments.siteid,
				contentId: arguments.contentId
			) />
			<!---
			<cfquery name="voteSum" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDbUsername()#" password="#application.configBean.getDbPassword()#">
				select 
					sum(rate) AS total 
				from 
					tcontent
					inner join tcontentratings on (tcontentratings.contentID=tcontent.contentID and tcontentratings.siteID=tcontent.siteID) 
				where 
					tcontent.active=1
					and tcontent.type='Page' 
					and tcontent.subType='Voting' 
					and tcontentratings.contentid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentid#" />
					and tcontentratings.siteid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteid#" /> 
					
					<!--- and tcontent.path like '%[probably a portal with a target subtype]%' --->
			</cfquery>
			--->

			<!--- get recordcount if total is no blank --->
			<cfif trim( voteSum.total ) IS NOT "">
				<cfset results = voteSum.total />
			</cfif>

			<cfreturn results />
		</cffunction>
		
		<cffunction name="addVotes" access="public" returntype="any" output="false">
			<cfargument name="userId" type="string" required="true" />
			<cfargument name="siteId" type="string" required="true" />
			<cfargument name="contentId" type="string" required="true" />
			<cfargument name="votes" type="numeric" required="true" />
			
			<cfset var results = structNew() />
			<cfset var currentUserVoteCount = getCurrentUserOverallVoteCount( 
				arguments.userId,
				arguments.siteId		
			) />
			<cfset var currentPageVoteCountByUser = getCurrentUserPageVoteCount(
				arguments.userId,
				arguments.contentId	
			) />
			<cfset var votesLeftToUse = variables.pluginConfig.getSetting( "maxUserVotes" ) - currentUserVoteCount />
			
			<Cfdump var="#arguments#" output="console" />
			
			<!--- default settings --->
			<cfset results.success = false />
			
			<!---
			<cfdump var="page:#currentPageVoteCountByUser# user:#currentUserVoteCount# #variables.pluginConfig.getSetting( "maxUserVotes" )#" output="console">
			--->
			
			<!--- only allow if the user has votes to use --->
			<cfif ( arguments.votes LTE currentPageVoteCountByUser ) 
				OR 
				(
					votesLeftToUse
					AND
					( ( votesLeftToUse + currentPageVoteCountByUser ) - arguments.votes ) GTE 0
				)
				OR 
				arguments.votes EQ 0>
				
				<!--- record vote --->
				<cfset application.raterManager.saveRate(
					arguments.contentId,
					arguments.siteId,
					arguments.userId,
					arguments.votes
				) />
				<!--- state that we are successful --->
				<cfset results.success = true />
			</cfif>
			
			<!--- get new page vote count --->
			<cfset results.totalPageVotes = getPageVoteCount( arguments.siteId, arguments.contentId ) />
			<cfset results.totalVotesLeft = variables.pluginConfig.getSetting( "maxUserVotes" ) - getCurrentUserOverallVoteCount( arguments.userId, arguments.siteId ) />
		
			<cfreturn variables.json.jsonEncode( results ) />

		</cffunction>

	</cfcomponent>