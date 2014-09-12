//  Copyright (c) 2010, David Van Puyvelde, Sales Engineering, Salesforce.com Inc.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

public with sharing class CSUtil {

    //gets the objecttype for a certain sfid
    public static String getObjectType(String sfid) {
        //Determine the object type of the id passed to this method
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String,String> keyPrefixMap = new Map<String,String>{};
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet){
           Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
           String tempName = r.getName();
           String tempPrefix = r.getKeyPrefix();
           keyPrefixMap.put(tempPrefix,tempName);
        }
        //prefix is just the first 3 chars
        String prefix = sfid.substring(0,3);
        String objecttype = keyPrefixMap.get(prefix);
        return objecttype;
    }
    
    //gets the object label for a certain sfid
    public static String getObjectLabel(String sfid) {
        //Determine the object type of the id passed to this method
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String,String> keyPrefixMap = new Map<String,String>{};
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet){
           Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
           String tempName = r.getLabel();
           String tempPrefix = r.getKeyPrefix();
           keyPrefixMap.put(tempPrefix,tempName);
        }
        //prefix is just the first 3 chars
        String prefix = sfid.substring(0,3);
        String objecttype = keyPrefixMap.get(prefix);
        return objecttype;
    }
    
    //sort the objecttype select list by label
    public static List<Selectoption> sortByLabel(List<Selectoption> origlist) {
        //create a Map with label as key and the selectoption as value
        //create a List with just the keys to sort it
        Map<String, Selectoption> ffmap = new Map<String, Selectoption>();
        List<String> tosort = new List<String>();
        for(Selectoption ff:origlist) {
            ffmap.put(ff.getLabel(), ff);
            tosort.add(ff.getLabel());
        }
        //now sort the list with the key values of the map
        tosort.sort();      
        //create a new list and fill it with by getting the keys from the sorted list and getting the objectss from the Map
        List<Selectoption> sortedlist = new List<Selectoption>();
        for(String s:tosort) {
            sortedlist.add(ffmap.get(s));
        }   
        return sortedlist;
    }

}