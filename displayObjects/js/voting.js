/* Copyright 2011 Blue River Interactive
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at

 *     http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * */
var ns = 'br-vm-'; // HTML class/ID namespace

 if ( typeof mura == "undefined" )
	 mura = {};
 
 if ( typeof mura.service == "undefined" )
	 mura.service = {};
	 
 mura.service.votingService = function() 
 {
		 this.config = {};
		 
		 this.getConfig = function ()
		 {
			 return this.config;
		 }
		 
	 	 this.addVote = function ( contentId, siteId, userId, votes )
		 {
	 		 var args = {};
	 		 
	 		 // set data
	 		 args.config = this.config;
	 		 args.contentId = contentId;
	 		 args.siteId = siteId;
	 		 args.userId = userId;
	 		 args.votes = votes;
	 		 // args.newPageVotes = parseInt( $("#"+ns+"voting-count-" + contentId).html() ) + votes;
	 		 // args.newUserVotes = parseInt( $("#"+ns+"voting-count-" + contentId + "-" + userId).html() ) + votes;
	 		 
	 		 // remove the class from the vote
	 		 $("#" + ns + "suggestionDetail" + " a." + ns + "myVote").removeClass( ns + "myVote" );
	 		 $("#suggestion-" + contentId + " a." + ns + "myVote").removeClass( ns + "myVote" );
	 		 // add the vote class to the number selected
	 		 $("#" + ns + "suggestionDetail" + " a." + ns + "vote-" + votes).addClass( ns + "myVote" );
	 		 $("#suggestion-" + contentId + " a." + ns + "vote-" + votes).addClass( ns + "myVote" );
	 	
	 		 //location.href='/plugins/muravoice/MuraProxy.cfc?method=remote&process=addVotes&userId=' + userId + '&siteId=' + siteId + '&contentId=' + contentId + '&votes=' + args.votes + '&returnFormat=json';
	 		
 			 $.ajax({
			   type: "get",
			   url: this.config.proxy,
			   data: 'method=remote&process=addVotes&userId=' + userId + '&siteId=' + siteId + '&contentId=' + contentId + '&votes=' + args.votes + '&returnFormat=json',
			   success: function(result)
			   		{
	 				 	var jsonObj = $.evalJSON( result );
				 		
				 		// if response is true then continue otherwise the user count has been hit
				 		if ( jsonObj.success == "true" )
				 		{
				 			// update the page votes
				 			$("#"+ns+"voting-count-" + args.contentId).html( jsonObj.totalpagevotes );
				
				 			// update your votes
				 			$("#"+ns+"voting-count-" + args.contentId + "-" + args.userId).html( args.votes );
				 			
				 			// update total votes left
				 			$("#"+ns+"totalUserVotesRemaining").html( jsonObj.totalvotesleft );
				 			
				 			// save how many votes are left
				 			args.config.totalvotesleft = jsonObj.totalvotesleft;
				 		} 
				 		else
				 		{
				 			alert( "Either an error has occured or you do not have " + args.votes + " available to use." );
				 		}
			   			
			   		}
			   });

		 }
		 
		 this.ping = function ()
		 {
			 alert( this.config.proxy );
		 }
 }