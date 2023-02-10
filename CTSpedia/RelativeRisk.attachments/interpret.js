/* This script uses the < character, which means it should be in a
    separate file for maximum compatibility.
    Assumes presence of jquery library.
*/



var Interp = {
    templateSource : /* not defined til page is ready: foswiki.pubUrl+ */
                 "/CTSpedia/RelativeRisk/estimate-CI_combos_RR.csv",
    isTemplateRead : false /* true after AJAX reads csv file into template */,
    isUserReady : false /* true when user has completed necessary inputs */,
    template : undefined /* will hold the csv file contents as a String */,

    /* some handy constants */
    /* indices for rows of estimate and upper and lower values
     */
    ilower : 1,
    iestimate : 0,
    iupper : 2,

/* general utility accessors */
/* return numeric code for substantive significance of row i */
    getSelectionValue: function(i)  {
	return document.getElementsByTagName("SELECT")[i].value;
    },

/*function return true if statistically significant.
Assumes all relevant values are filled in .
*/
    isStatSig : function() {
	return (1-Interp.getCoefficient(Interp.ilower))*
	(1-Interp.getCoefficient(Interp.iupper))>0;
    },


/* return the coefficient in row i of body, in regular, not logged form */
    getCoefficient : function(i) {
	var v = document.getElementsByTagName("TR")[i+1].getElementsByTagName("INPUT")[1].value;
	if ($.trim(v).length == 0)
	    return Number.NaN;
	return Number(v);
    },

/* return the n in f-fold change for row i, as a string with 2 digits */
    getFactor : function(i) {
	var factor = Interp.getCoefficient(i);
	return (+factor).toFixed(2);
    },

/* return nn-fold risk increase or decrease */
    getFullFactor : function(i) {
	var factor = Interp.getCoefficient(i);
	return Math.abs(factor).toFixed(2)+" risk "+
	(Number(factor)>0 ? "increase" : "decrease");
    },

    /* return an object with entries indicating whether good numbers are present */
    checkCoefficientPresent : function() {
	var v = Interp.getCoefficientValues();
	return {
	    estimate : ! isNaN(v.estimate),
		lower : ! isNaN(v.lower),
		upper : ! isNaN(v.upper)
	};
    },

    /* return object with the field values */
    getCoefficientValues : function() {
	return {
	    estimate : Interp.getCoefficient(Interp.iestimate),
	    lower : Interp.getCoefficient(Interp.ilower),
	    upper : Interp.getCoefficient(Interp.iupper)
	};
    },

    /* return true if coefficients are sane, as far as we can tell */
    checkCoefficientOrdering : function() {
	/* v for value */
	var v = Interp.getCoefficientValues();
	/* n prefix for "is numeric" as opposed to blank */
	var n = Interp.checkCoefficientPresent();
	if (n.estimate && n.lower && v.estimate < v.lower) {
	    alert("The lower confidence limit should be less than the estimate.");
	    return false;
	};
	if (n.estimate && n.upper && v.upper < v.estimate) {
	    alert("The upper confidence limit must exceed the estimate.");
	    return false;
	}
	if (n.lower && n.upper && n.upper < n.lower) {
	    alert("The upper confidence limit must exceed the lower limit.");
	    return false;
	}
	return true;
    },

    /* do all coefficient checks */
    checkBasicCoefficient : function() {
	return Interp.checkCoefficientOrdering();
    },

    /* return an object with the numeric codes in the interpretation fields */
    getSubstance : function() {
	return {
	    estimate : Interp.getSelectionValue(Interp.iestimate),
	    lower : Interp.getSelectionValue(Interp.ilower),
	    upper : Interp.getSelectionValue(Interp.iupper)
	};
    },

    /* return true/false for whether valid values have been picked */
    checkSubstancePresent : function() {
	var v = Interp.getSubstance();
	return {
	    estimate : Math.abs(v.estimate)<3,
	    lower : Math.abs(v.lower)<3,
	    upper : Math.abs(v.upper)<3
		};
    },


    /* returns true if all tests of non-missing substantive 
       interpretations pass.
       Otherwise pops up an alert and returns false.
       true does not mean all are good; some may be blank */
    checkBasicSubstance : function(evt) {
	var v = Interp.getSubstance();
	var p = Interp.checkSubstancePresent();
	/* I am not going to check any association between
	   numeric and substantive values. */
	if (p.estimate && p.upper && p.lower) {
	    var dup = v.upper - v.estimate;
	    var ddown = v.estimate - v.lower;
	    if (dup * ddown < 0) {
		alert("Your substantive interpretation of the estimate lies outside the range of interpretations for the confidence limits.");
		return  false;
	    }
	}
	return true;
    },

    /* public function.  It will write paragraph if all is done.*/
    checkSubstance : function(evt) {
	if (Interp.checkBasicSubstance(evt) == false)
	    return false;
	if (Interp.areAllPresent() && Interp.checkBasicCoefficient()) {
	    Interp.isUserReady = true;
	    Interp.writeup();
	    return true;
	}
	return false;
    },

    /* analogue for coefficients */
    checkCoefficient : function(evt) {
	if (Interp.checkBasicCoefficient(evt) == false)
	    return false;
	if (Interp.areAllPresent() && Interp.checkBasicSubstance()) {
	    Interp.isUserReady = true;
	    Interp.writeup();
	    return true;
	}
	return false;
    },


    /* Return true if all user values have been filled in.
       That does not guarantee they are sensible.*/
    areAllPresent : function() {
	var p = Interp.checkSubstancePresent();
	if (p.lower && p.estimate && p.upper) {
	    p = Interp.checkCoefficientPresent();
	    return p.lower && p.estimate && p.upper;
	};
	return false;
    },

// return text fragment characterizing the substantive and statical 
// significance of the result in row i.
    getSubSig : function(i){
    var substance = Interp.getSelectionValue(i);
    if (substance=0)
	return "clinically unimportant " + Interp.getFullFactor(i);
    if (Math.abs(substance) == 2)
	return "clinically important" + Interp.getFullFactor(i);
    return Interp.getFullFactor(i) + ", which might be considered clinically important";
    },

/* compute log from regular and vice versa */
    computeregular : function(elem) {
	var x = $(elem).closest('td').next('td').find('input')
	x.val(Math.exp(elem.value));
	Interp.checkCoefficient();
       },

    computelog : function(elem) {
	var x = $(elem).closest('td').prev('td').find('input')
	x.val(Math.log(elem.value));
	Interp.checkCoefficient();
       },

/* return true if inputs are valid */
    checkValidity : function() {
    var i;
    for (i=0; i < 3; i++) {
      if (Math.abs(Interp.getSelectionValue(i))>2) {
        alert("Please select the substantive interpretation for all 3 terms.");
        return false;
      }
    }
    return true;
    },


/* There are several tests for several situations.
1. Determine if results entered are sensible.
   a) estimate between upper and lower, numerically and substantively;
   b) identification between + and - coefficient and harm or benefit
    is consistent.
2. Determine if all info needed to display an answer is there.
3. Statistical significance determination
   a) can we tell based on results if estimate is stat sig?
      If we can tell, display the results.
   b) if we can't tell, but all other info is entered, ask.
    Why do we need to ask if we have the numerical values?
*/

/* for relative risk, I think we assume the outcome is bad, so
    negative effects are good and positive ones are bad
*/
    writeup : function(elem) {
	if (!(Interp.isTemplateRead && Interp.isUserReady))
	    return;
	var mymeaning = function(i) {
	    /* leading space for Imporant Harm is essential for match */
	    var words = ["Important Harm", "Maybe Important Harm",
		"Small, Unimportant", "Maybe Important Benefit", 
			 "Important Benefit"];
	    return words[+i+2];
	}

	// note the change in ordering from the rows in the table 
	var lower = Interp.getSelectionValue(Interp.ilower);
	var estimate = Interp.getSelectionValue(Interp.iestimate);
	var upper = Interp.getSelectionValue(Interp.iupper);

	var limits = [ lower, estimate, upper ];
	var myStatSig = Interp.isStatSig();
	if (myStatSig)
	    myStatSig="Yes";
	else
	    myStatSig="No";
    
	/* we don't currently use these
	var mySubSig = function(i) Math.abs(Interp.getSelectionValue(i));

	
	var direction;
	if (lower < 0)
	    direction = "increase";
	else
	    direction = "reduction";
	*/
    
	if (!Interp.checkValidity()) {
	    Interp.isUserRead = false;
	    return false;
	}
    
	var txt = Interp.getTemplate(mymeaning(estimate), mymeaning(lower),
				     mymeaning(upper), myStatSig);
	if (typeof txt == "undefined") {
	    /* for obscure cases that slip through.
	     E.g., lower confidence limit coefficient is same sign as estimate,
	    but substantive interpretation is in a different direction.
	    */
	    alert("I'm sorry; I don't think that combination of inputs is possible.");
	    Interp.isUserReady = false;
	    return false;
	}

	txt = txt.replace(/[0E]\.EE/g, Interp.getFactor(Interp.iestimate));
	txt = txt.replace(/[0L]\.LL/g, Interp.getFactor(Interp.ilower));
	txt = txt.replace(/[0U]\.UU/g, Interp.getFactor(Interp.iupper));
	var elem = document.createElement("p");
	var txt1 = document.createTextNode(txt);
	elem.appendChild(txt1);
	var panel = document.getElementById("suggested");
	if (panel.hasChildNodes())
	    panel.removeChild(panel.firstChild);
	$('#sampleHead').css("visibility", "visible");
	panel.appendChild(elem);
    },

    /* return the raw text of the template with the indicated *string* arguments */
    getTemplate : function(est, low, hi, sig) {
	var s = "\\s*"; /* regexp for space */
	var q0 = '"'+s;
	var q = s+'","'+s;
	var qn = s+'",'+s
	var rowSpec = q0.concat(est, q, low, q, hi, qn, sig, ',');
	var m = Interp.template.match(rowSpec);
	if (!m){
	    return undefined;
	}
	var i = m.index + m[0].length + 1; /* just after " at template start */
	var j = Interp.template.indexOf('"', i); /* closing " */
	return Interp.template.substring(i, j);
    },

    checkNumeric : function(evt) {
	var v = $(evt.target).val()
	v = $.trim(v)
	if (v.length == 0 || v =="-" || v=="." || v=="-.")
	    return;
	var n = Number(v)
	if (isNaN(n))
	    alert(v + " is not a number.");
    },


    gotTemplateSource : function(data, status) {
	if (status != "success")
	    alert("Sorry.  I couldn't get necessary data from the server.  Try later.");
	Interp.template = data;
	Interp.isTemplateRead = true;
	Interp.writeup();
    },

	/* do some initial setup if needed. */
    setup : function() {
	Interp.templateSource = foswiki.pubUrl+Interp.templateSource;
	$('#nojs').hide();
	$('#hasjs').css("visibility", "visible");
	$('#sampleHead').css("visibility", "hidden");
	$(".numeric").keyup(Interp.checkNumeric);
	$.get(Interp.templateSource, {contenttype : "text/csv", skin : "None"} , Interp.gotTemplateSource)
    }
	// warning MS IE7 (at least) gags if there is a , here

};


$(document).ready(Interp.setup);
