<cfcomponent output="false" extends="mura.plugin.pluginGenericEventHandler">
	
	<!--- HTML class/ID namespace --->
	<cfset ns = 'br-vm-' /> 


	<cffunction name="onApplicationLoad">
		<cfargument name="$" />

		<cfset var subType = "" />
		<cfset var assignedSites = pluginConfig.getAssignedSites() />
		<cfset var proxy = createObject( "component", "#pluginConfig.getPackage()#.muraProxy").init() />
		<cfset var votingDAO = createObject( "component", "#pluginConfig.getPackage()#.lib.votingDAO").init() />
		<cfset var extendSet = "" />
		<cfset var attribute = structNew() />

		<!--- get an instance of them proxy and store it into mem --->
		<cfset pluginConfig.getApplication().setValue( "proxy", proxy ) />
		<!--- set the voting DAO and store into mem --->
		<cfset pluginConfig.getApplication().setValue( "votingDAO", votingDAO ) />

		<!--- loop over assigned sites and add in portal subtype --->
		<cfloop query="assignedSites">

			<!--- ****************************** --->
			<!--- CREATE PORTAL/VOTING SUBTYPE --->
			<!--- ****************************** --->
			<cfscript>
				// create the voter portal subtype
				subType = application.classExtensionManager.getSubTypeBean();
				subType.setType( "Portal" );
				subType.setSubType( "Voting" );
				subType.setSiteID( assignedSites.siteId );
				subType.load();
				subType.save();
			</cfscript>

			<!--- // place in voting types (open, closed, being discussed) --->
			<cfset extendSet = subType.getExtendSetByName( "Vote Details" ) />
			<cfset extendSet.setName("Vote Details") />
			<cfset extendSet.setContainer("Basic")>
			<cfset extendSet.save()>

			<!--- ********************* --->
			<!--- CHECK AND ADD AUTOAPPROVE ATTRIBUTE IF DOES NOT EXIST --->
			<!--- ********************* --->
			<cfset attribute = extendSet.getAttributeByName( "voteAutoApprove" ) />
			<cfset attribute.setLabel( "Auto Approve Topics" ) />
			<cfset attribute.setType( "RadioGroup" ) />
			<cfset attribute.setOptionList( "Yes^No" ) />
			<cfset attribute.setOptionLabelList( "Yes^No" ) />
			<cfset attribute.setDefaultValue( "Yes" ) />
			<cfset attribute.save() />

			<!--- ****************************** --->
			<!--- CREATE PAGE/VOTING SUBTYPE --->
			<!--- ****************************** --->
			<cfscript>
				// create the voter page subtype
				subType = application.classExtensionManager.getSubTypeBean();
				subType.setType( "Page" );
				subType.setSubType( "Voting" );
				subType.setSiteID( assignedSites.siteId );
				subType.load();
				subType.save();
			</cfscript>

			<!--- // place in voting types (open, closed, being discussed) --->
			<cfset extendSet = subType.getExtendSetByName( "Vote Details" ) />
			<cfset extendSet.setName("Vote Details") />
			<cfset extendSet.setContainer("Basic")>
			<cfset extendSet.save()>
			<!--- ********************* --->
			<!--- CHECK AND ADD STATUS ATTRIBUTE IF DOES NOT EXIST --->
			<!--- ********************* --->
			<cfset attribute = extendSet.getAttributeByName( "voteStatus" ) />
			<cfset attribute.setLabel( "Status" ) />
			<cfset attribute.setType( "SelectBox" ) />
			<cfset attribute.setOptionList( pluginConfig.getSetting("displayableGroupsByStatus") ) />
			<cfset attribute.setOptionLabelList( pluginConfig.getSetting("displayableGroupsByStatus") ) />
			<cfset attribute.setDefaultValue( listFirst(pluginConfig.getSetting("displayableGroupsByStatus"),"^") ) />
			<cfset attribute.save() />

			<!--- ********************* --->
			<!--- CHECK AND ADD ADMINRESPONSE ATTRIBUTE IF DOES NOT EXIST --->
			<!--- ********************* --->
			<cfset attribute = extendSet.getAttributeByName( "voteAdminResponse" ) />
			<cfset attribute.setLabel( "AdminResponse" ) />
			<cfset attribute.setType( "HTMLEditor" ) />
			<cfset attribute.save() />

			<!--- ********************* --->
			<!--- CHECK AND ADD ADMINRESPONSE ATTRIBUTE IF DOES NOT EXIST --->
			<!--- ********************* 
			<cfset attribute = extendSet.getAttributeByName( "voteAccepted" ) />
			<cfset attribute.setLabel( "Accepted" ) />
			<cfset attribute.setType( "RadioGroup" ) />
			<cfset attribute.setOptionList( "Yes^No" ) />
			<cfset attribute.setOptionLabelList( "Yes^No" ) />
			<cfset attribute.setDefaultValue( "Yes" ) />
			<cfset attribute.save() />
			--->
		</cfloop>
		
		<cfset pluginConfig.addEventHandler(this)>

	</cffunction>

	<cffunction name="onPortalVotingBodyRender" returntype="any" output="false">
		<cfargument name="$" />

		<cfset var votingPages = "" />
		<cfset var node = "" />
		<cfset var categories = "" />
		<cfset var headerBody = "" />
		<cfset var category = "" />
		<cfset var newBody = "" />
		<cfset var contentBean = "" />
		<cfset var suggestionBean = "" />
		
				<!--- set default save option --->
			<cfset $.event( "votingSuggestionSaved", false ) />

			<!--- submit (save) suggestion --->
			<cfif $.event().valueExists( "btn_votingSuggestionSubmit" )
				AND trim( $.event( "votingSuggestionTitle" ) IS NOT "" )
				AND trim( $.event( "votingSuggestion" ) IS NOT "" )
				AND len( $.currentUser().isLoggedIn() )
				AND ( pluginConfig.getSetting( "maxVotesPerPage" ) - pluginConfig.getApplication().getValue( "proxy" ).getCurrentUserOverallVoteCount( userid:$.currentUser("userID"), siteid: $.event( "siteid" ) ) )>
				<!--- create suggestion --->
				<cfset suggestionBean = pluginConfig.getApplication().getValue( "votingDAO" ).saveSuggestion(
					title: $.event( "votingSuggestionTitle" ),
					userid: $.currentUser("userID"),
					suggestion: $.event( "votingSuggestion" ),
					parentId: $.event( "contentBean" ).getContentId(),
					approved: $.content( "voteAutoApprove" ),
					siteid: $.event("siteID")
				) />

				<!--- add one of your votes to the new suggestion --->
				<cfset pluginConfig.getApplication().getValue( "proxy" ).addVotes(
					userid: $.currentUser("userID"),
					siteid: $.event( "siteid" ),
					contentid: suggestionBean.getContentId(),
					votes: $.event( "suggestion_votes" )
				) />

				<!--- set that the suggestion has been saved --->
				<cfset $.event( "votingSuggestionSaved", true ) />
				<!--- create a message that will get displayed to the screen --->
				<cfset $.event( "message", "Your suggestion has been submitted!" ) />
			</cfif>

			<!--- get voting page details --->
			<cfset votingPages = pluginConfig.getApplication().getValue( "votingDAO" ).getVotingPortalPages(
				siteId: $.event( "siteId" ),
				parentId: $.content("contentID"),
				voteStatus: $.event( "voteStatus" ),
				searchPhrase: $.event( "searchPhrase" )
			) />

			<!--- get categories --->
			<cfset categories = pluginConfig.getSetting( "displayableGroupsByStatus" ) />

			<!--- header --->
			<cfsavecontent variable="headerBody">
				<cfoutput>
					<!--- records found in portal 
					<div id="#ns#totalPagesFound">
						<p><span>#votingPages.getRecordcount()#</span> Pages found!</p>
					</div>
					--->
					<!--- group by fields --->
					<div id="#ns#votingGroups">
						<dl>
							<dt>Group by:</dt>
							<dd class="#ns#all">[ <a href="#$.content().getURL()#">All</a> ]</dd>
							<!---<dd class="#ns#accepted">[ <a href="#$.content().getURL(queryString='accepted=true')#">Accepted</a> ]</dd>--->
							<cfloop list="#categories#" delimiters="^" index="category">	
								<dd class="#ns#category">[ <a href="#$.content().getURL(queryString='voteStatus=#urlEncodedFormat(category)#')#">#HTMLEditFormat(category)#</a> ]</dd>
							</cfloop>
						</dl>
					</div>

					<!--- display a message if one is available --->
					<cfif $.event().valueExists( "message" )>
						<div class="#ns#message">
							<p>#$.event( "message ")#</p>
						</div>
					</cfif>

					<!--- suggestion box only if use is logged in --->
					#buildSearchSuggestionBox( $ )#

					<!--- create create button --->
					<cfif $.event().valueExists( "searchPhrase" )
						AND $.currentUser().isLoggedIn()
						AND ( pluginConfig.getSetting( "maxVotesPerPage" ) - pluginConfig.getApplication().getValue( "proxy" ).getCurrentUserOverallVoteCount( userid:$.currentUser("userID"), siteid: $.event( "siteid" ) ) )>
						#buildSuggestionBox( $ )#
					</cfif>
				</cfoutput>
			</cfsavecontent>

			<cfif votingPages.hasNext()>
			<!--- loop over rs --->
			<cfloop condition="votingPages.hasNext()">
				<cfset contentBean=votingPages.next()>
				<!--- create node --->
				<cfsavecontent variable="node">
					<cfoutput>
						<li class="#ns#suggestion" id="suggestion-#contentBean.getContentId()#">
							<div class="#ns#ballotBox">
								#buildVotingWidget( $, contentBean )#
							</div>
							<dl id="#ns#suggestion-#contentBean.getcontentId()#" class="#ns#details">
								<dt class="#ns#title"><a href="#contentBean.getURL()#">#HTMLEditFormat(contentBean.getTitle())#</a></dt>
								<dd class="#ns#description">
									#contentBean.getBody()#
								</dd>
								<dd class="#ns#meta">
									<p class="#ns#submitter">submitted by: <span>#HTMLEditFormat(contentBean.getLastUpdateBy())#</span></p>
									<p class="#ns#comments"><a href="#contentBean.getURL(queryString='##comments')#">#contentBean.getStats().getComments()# comments</a></p>
								</dd>
								<dd class="#ns#response">
									<p class="#ns#status">
										<strong>Status:</strong>
										<em><span>#contentBean.getValue( "voteStatus" )#</span></em>
									</p>
									<cfif trim( contentBean.getValue("voteAdminResponse") ) IS NOT "">
										<!--- admin response: --->
										<div class="#ns#detail">
											#contentBean.getValue("voteAdminResponse")#
										</div>
									</cfif>
								</dd>
							</dl>
						</li>
					</cfoutput>
				</cfsavecontent>

				<!--- ammend node --->
				<cfset newBody = newBody & node />
			</cfloop>
			
			
			<cfif len(newBody)>
				<cfset newBody = '<ul id="' & ns & 'suggestions">' & newBody & '</ul>' />
			</cfif>
			
			<cfelse>
				<cfsavecontent variable="node">
				<cfoutput>
					<p>
					<cfif len($.event("voteStatus"))>
					There are currently no items set to <strong>"#HTMLEditFormat($.event("voteStatus"))#"</strong>.
					<cfelse>
					There are currently no items.
					</cfif>
					</p>
					</cfoutput>
				</cfsavecontent>
				 <cfset newBody = newBody & node />
			</cfif>

			<!--- emmand in amount of votes available --->
			<cfset newBody = buildTotalVotesRemaining( $ ) & newBody & addJS( $ ) />

			<!--- assign new body --->
			<cfreturn $.content("body") & headerBody & newBody/>
	

	</cffunction>

	<cffunction name="onPageVotingBodyRender" returntype="any" output="false">
		<cfargument name="$" />

		<cfset var newBody = "" />
		<cfset var commentCount = $.getBean("contentGateway").getCommentCount($.event("siteID"),$.content("contentID")) />

		<!--- if there is a comment submitted --->
		<cfif $.event().valueExists( "comments" )>
			<cfset commentCount = commentCount + 1 />
		</cfif>

		<!--- create node --->
		<cfsavecontent variable="newBody">
			<cfoutput>
				<div id="#ns#suggestionDetail" class="#ns#suggestion">
					<div class="#ns#ballotBox">
						#buildVotingWidget( $ , $.content() )#
						#buildTotalVotesRemaining( $ )#
					</div>
					<div class="#ns#details">
						<div class="#ns#description">
							#$.content("body")#
						</div>
						<div class="#ns#meta">
							<p class="#ns#submitter">submitted by: <span>#$.content("lastUpdateBy")#</span></p>
							<p class="#ns#comments"><a href="##comments">#commentCount# comments</a></p>
						</div>
						<div class="#ns#response">
							<p class="#ns#status">
								<strong>Status:</strong>
								<em><span>#$.content( "voteStatus" )#</span></em>
							</p>
							
							<cfif trim( $.content("voteAdminResponse") ) IS NOT "">
								<!--- admin response: --->
								<div class="#ns#detail">
									#$.content("voteAdminResponse")#
								</div>
							</cfif>
						</div>
						#$.dspObject( "comments",'' )#
					</div>
				</div>
				
				#addJS( $ )#
			</cfoutput>
		</cfsavecontent>

		<!--- assign new body --->
		<cfreturn newbody />

	</cffunction>

	<!--- *************************************** --->
	<!--- PRIVATE --->
	<!--- *************************************** --->
	
	<cffunction name="buildVotingWidget" access="private" returntype="any" output="false">
		<cfargument name="$" />
		<cfargument name="contentBean" />

		<cfset var widgetContext = "" />
		<cfset var pageVotes = 0 />
		<cfset var userVotes = 0 />
		<cfset var vote = 0 />

		<!--- get votes for page --->
		<cfset pageVotes = pluginConfig.getApplication().getValue( "proxy" ).getPageVoteCount(
			$.event( "siteId" ),
			arguments.contentBean.getContentId()
		) />

		<!--- user votes for page total user votes for page --->
		<cfif $.currentUser().isLoggedIn()>
			<cfset userVotes = pluginConfig.getApplication().getValue( "proxy" ).getCurrentUserPageVoteCount(
				$.currentUser("userID"),
				arguments.contentBean.getContentId()
			) />
		</cfif>

		<cfsavecontent variable="widgetContext">
			<cfoutput>
				<div class="#ns#voting">
					<div class="#ns#totals">
						<em id="#ns#voting-count-#arguments.contentBean.getContentId()#">#pageVotes#</em> <span>votes</span>
					</div>
					<cfif $.currentUser().isLoggedIn() AND contentBean.getValue( "voteStatus" )  eq "open">
						<div class="#ns#myVotes">
							<div id="#ns#voting-count-#arguments.contentBean.getContentId()	#-#$.currentUser('userID')#" class="#ns#votesCast">
								<span>#userVotes#</span>
							</div>
							<dl>
								<dt>vote</dt>
								<dd>
									<ol>
										<!--- create votes only if the topic is not closed --->
										<cfloop from="0" to="#pluginConfig.getSetting( "maxVotesPerPage" )#" index="vote">
											<!--- DEVNOTE: The ID's on the links below need to be unique or be changed to classes --->
											<li><a id="#ns#vote_#vote#" class="#ns#vote-#vote#<cfif (userVotes EQ vote)> #ns#myVote</cfif>" href="javascript:votingService.addVote( '#arguments.contentBean.getContentId()#', '#$.event( "siteId" )#', '#$.currentUser('userID')#', #vote# );">#vote#</a></li>
										</cfloop>
									</ol>
								</dd>
							</dl>
						</div>
					</cfif>
				</div>
			</cfoutput>
		</cfsavecontent>

		<cfreturn widgetContext />

	</cffunction>

	<cffunction name="buildSearchSuggestionBox" access="private" returntype="any" output="false">
		<cfargument name="$" />

		<cfset var body = "" />

		<cfsavecontent variable="body">
			<cfoutput>
				<form name="frm_votingSuggestionSearch" id="#ns#frm_votingSuggestionSearch" action="./" method="post">
					<div>
						<label for="#ns#SuggestionSearchTerms">I'd like to suggest:</label>
						<input type="text" name="searchPhrase" value="#HTMLEditFormat($.event( 'searchPhrase'))#" id="#ns#SuggestionSearchTerms" />
						<input type="submit" value="Search" name="btn_votingSearchSubmit" />
					</div>
				</form>
			</cfoutput>
		</cfsavecontent>

		<cfreturn body />
	</cffunction>

	<cffunction name="buildSuggestionBox" access="private" returntype="any" output="false">
		<cfargument name="$" />

		<cfset var body = "" />

		<cfsavecontent variable="body">
			<cfoutput>
				<a name="suggestionBox" id="#ns#makeSuggestion" href="##suggestionBox"><span>Make a suggestion</span></a>
				<div id="#ns#suggestionBox">
					<form name="frm_votingSuggestion" id="#ns#frm_votingSuggestion" action="./" method="post">
						<input type="hidden" name="siteId" value="#HTMLEditFormat($.event( 'siteId' ))#" />
						<ol>
							<li class="req">
								<label for="#ns#votingSuggestionTitle">Title:<ins> (required)</ins></label>
								<input class="required" type="text" id="#ns#votingSuggestionTitle" name="votingSuggestionTitle" value="#HTMLEditFormat($.event( "searchPhrase" ))#" />
							</li>
							<li class="req">
								<label for="#ns#votingSuggestion">Suggestion:<ins> (required)</ins></label>
								<textarea class="required" id="#ns#votingSuggestion" name="votingSuggestion" cols="40" rows="10"></textarea>
							</li>
							<li class="req">
								<label for="#ns#suggestion_votes">Votes for suggestion:<ins> (required)</ins></label> <!--- DEVNOTE: to keep the namespacing, should we change the id to "votingSuggestionVotes"? --->
								<select id="#ns#suggestion_votes" name="suggestion_votes">
									<cfloop from="1" to="#pluginConfig.getSetting( "maxVotesPerPage" )#" index="vote">
										<option value="#vote#">#vote#</option>
									</cfloop>
								</select>
							</li>
						</ol>
						<div class="buttons #ns#buttons">
							<input type="Submit" value="Submit" name="btn_votingSuggestionSubmit" />
							<!--- <p>Requirement: One vote must be used</p> ---> <!--- DEVNOTE: probably won't need this now --->
						</div>
					</form>
				</div>
			</cfoutput>
		</cfsavecontent>

		<cfreturn body />
	</cffunction>

	<cffunction name="buildTotalVotesRemaining" access="private" returntype="any" output="false">
		<cfargument name="$" />

		<cfset var totalVotesRemaining = "" />
		<cfset var totalUserVotesAvailable = 0 />

		<!--- attempt to get voting information only if user is logged in --->
		<cfif $.currentUser().isLoggedIn()>
			<cfset totalUserVotesAvailable = pluginConfig.getSetting( "maxUserVotes" ) - pluginConfig.getApplication().getValue( "proxy" ).getCurrentUserOverallVoteCount( $.currentUser("userID"),$.event( "siteId" ) ) />
		</cfif>

		<!--- if user votes are less than 0 then force to 0 --->
		<cfif totalUserVotesAvailable LT 0>
			<cfset totalUserVotesAvailable = 0 />
		</cfif>

		<!--- build div for user count --->
		<cfsavecontent variable="totalVotesRemaining">
			<cfoutput>
				<cfif $.currentUser().isLoggedIn()>
					<div id="#ns#yourVotesAvailable">
						<p>
							You have <strong id="#ns#totalUserVotesRemaining">#totalUserVotesAvailable#</strong> votes remaining.
						</p>
					</div>
				</cfif>
			</cfoutput>
		</cfsavecontent>

		<cfreturn totalVotesRemaining />
	</cffunction>

	<cffunction name="addJS" access="private" returntype="any" output="false">
		<cfargument name="$" />

		<cfset $.loadJSLib() />
		<!--- work around to make sure js is loaded into the queue --->
		<cfset pluginConfig.setSetting( "pluginMode", "object" )  />

		<cfset pluginConfig.addToHTMLHeadQueue( "displayObjects/html_head.cfm" ) />
	</cffunction>

</cfcomponent>