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
<cfset pluginConfig = application.pluginManager.getConfig( "muravoice" ) />

<cfoutput>
	<link rel="stylesheet" type="text/css" href="#$.globalConfig('context')#/plugins/#pluginConfig.getDirectory()#/displayObjects/css/votingManager.css" />
	<script type="text/javascript" src="#$.globalConfig('context')#/plugins/#pluginConfig.getDirectory()#/displayObjects/js/voting.js"></script>
	<script type="text/javascript" src="#$.globalConfig('context')#/plugins/#pluginConfig.getDirectory()#/displayObjects/js/jquery.json-1.3.min.js"></script>
	<script type="text/javascript" src="#$.globalConfig('context')#/plugins/#pluginConfig.getDirectory()#/displayObjects/js/jquery.validate.min.js"></script>

	<script type="text/javascript">
		var ns = 'br-vm-'; // HTML class/ID namespace
		var votingService = new mura.service.votingService();

		// config
		votingService.config = {
			proxy: '#$.globalConfig("context")#/plugins/#pluginConfig.getDirectory()#/muraProxy.cfc',
			<cfif len( getAuthUser() ) AND ( pluginConfig.getApplication().getValue( "proxy" ).getCurrentUserOverallVoteCount( listGetAt( getAuthUser(), 1, "^" ), event.getValue( "siteid" ) ) LT pluginConfig.getSetting( "maxUserVotes" ) ) >
				totalvotesleft: #evaluate( pluginConfig.getSetting( "maxUserVotes" ) - pluginConfig.getApplication().getValue( "proxy" ).getCurrentUserOverallVoteCount( listGetAt( getAuthUser(), 1, "^" ), event.getValue( "siteid" ) ) )#,
			<cfelse>
				totalvotesleft: 0,
			</cfif>
			maxVotes: #pluginConfig.getSetting( "maxUserVotes" )#
		}

		
		$(document).ready(function(){

			// Reveal suggestion form
			$('##'+ns+'suggestionBox').hide();
			$('a##'+ns+'makeSuggestion').click(function(){
				$('##'+ns+'suggestionBox').slideDown();
				return false;
			});


			// validate the form
			// submit suggestion form validation
			$('##'+ns+'frm_votingSuggestion').validate({
			 	submitHandler: function(form) {
					if ( $('##'+ns+'suggestion_votes').val() <= votingService.getConfig().totalvotesleft )
			   			form.submit();
			   		else
			   			alert( 'You do not have that many votes to use.' );
			 	}
			});


			//voting toggle
			$('.'+ns+'suggestion div.'+ns+'voting div.'+ns+'myVotes dl dd').hide();
			$('.'+ns+'suggestion div.'+ns+'ballotBox').hover(
				function(){
					$(this).find('.'+ns+'myVotes dd').slideDown();
				},
				function(){
					$(this).find('.'+ns+'myVotes dd').slideUp();
				}
			);

		});
	</script>
</cfoutput>