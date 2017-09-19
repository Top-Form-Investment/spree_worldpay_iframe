/**
 * Worldpay Hosted Payment Pages - Integration Library
 * ---------------------------------------------------------------------------------------------------------------------
 * Version: 12.2
 * ---------------------------------------------------------------------------------------------------------------------
 * This library is used by merchants for integrating HPP payment-pages on their site, using either of the following:
 * - Iframe
 * - Lightbox
 * - Redirect
 */

'use strict';

/**
 * Library namespace.
 */
var WPCL = WPCL || {};

/**
* Library constructor - holds default values for an instance of library
*/
WPCL.Library = function() {

    this.options = {
        iframeIntegrationId: '',
        iframeBaseURL: '',
        iframeHelperURL: '',

        url: 'https://payments.worldpay.com/',
        type: 'lightbox',
        inject: 'default',
        target: null,
        trigger: null,
        lightboxMaskOpacity: 50,
        lightboxMaskColor: '#000000',
        accessibility: false,
        language: 'en',
        country: '',
        preferredPaymentMethod: '',

        // Result URLs
        successURL: '',
        cancelURL: '',
        failureURL: '',
        pendingURL: '',
        errorURL: '',

        // Result callback
        resultCallback: null,

        // Development
        debug: false
    };

    this.iframeTitlesLanguageMap = {
        'bg':'Ð¡Ñ‚Ñ€Ð°Ð½Ð¸Ñ†Ð¸ Ð·Ð° Ð¿Ð»Ð°Ñ‰Ð°Ð½Ðµ',
        'bs':'Stranice za plaÄ‡anje',
        'ca':'PÃ gines de pagament',
        'cs':'PlatebnÃ­ strÃ¡nky',
        'cy':'Tudalennau talu',
        'da':'Betalingssider',
        'de':'Zahlungsseiten',
        'el':'Î£ÎµÎ»Î¯Î´ÎµÏ‚ Ï€Î»Î·ÏÏ‰Î¼Î®Ï‚',
        'en':'Payment Pages',
        'es':'PÃ¡ginas de pago',
        'et':'Makse lehekÃ¼ljed',
        'fi':'Maksusivut',
        'fr':'Pages de paiement',
        'hi':'à¤­à¥à¤—à¤¤à¤¾à¤¨ à¤ªà¥‡à¤œ',
        'hr':'Stranice za plaÄ‡anje',
        'hu':'FizetÃ©si oldalak',
        'it':'Pagine di pagamento',
        'ja':'æ±ºæ¸ˆãƒšãƒ¼ã‚¸',
        'ko':'ê²°ì œ íŽ˜ì´ì§€',
        'lv':'MaksÄjumu lapas',
        'nl':'Betaalpaginaâ€™s',
        'no':'Betalingssider',
        'pl':'Strony pÅ‚atnoÅ›ci',
        'pt':'PÃ¡ginas do pagamento',
        'ro':'Pagini de platÄƒ',
        'ru':'Ð¡Ñ‚Ñ€Ð°Ð½Ð¸Ñ†Ñ‹ Ð¾Ð¿Ð»Ð°Ñ‚Ñ‹',
        'si': 'à¶œà·™à·€à·“à¶¸à·Š à¶´à·’à¶§à·”',
        'sk':'WebovÃ© strÃ¡nky na vykonÃ¡vanie platieb',
        'sl':'PlaÄilne strani',
        'sv':'Betalningssidor',
        'tr':'Ã–deme SayfalarÄ±',
        'zh':'æ”¯ä»˜é¡µé¢',
        'th':'à¸«à¸™à¹‰à¸²à¸Šà¸³à¸£à¸°à¹€à¸‡à¸´à¸™',
        'zh_TW': 'æ”¯ä»˜é é¢',
        'es_CO':'PÃ¡ginas de pago',
        'pt_BR':'PÃ¡ginas de pagamento'
    };

    // Padding for negative margins
    this.padding = 15;
    this.lightboxWidth = 780;

    // String namespace
    this.prefix = 'wp-cl';
    this.wpName = this.prefix; //the format of the name is  this.prefix-this.options.target

    // Flag for indicating if post message is working
    this.isPostMessage = false;

    // Flag for indicating if SDK info already sent
    this.sdkInfoAlreadySent = false;

    // Flag for indicating if fake load event detected
    this.isFakeLoadEvent = false;

    // String for indicating the iframe title and language
    this.iframeTitleAndLanguage = null;

    // Variable that wraps the inject function
    this.onloadInject = null;

};

/**
 * Library prototype - defines functions, private and public, for each instance created.
 */
WPCL.Library.prototype = (function(){

    /**
     * Sets up the library to control an instance of payment-pages.
     *
     * @param merchantOptions
     */
    var setup = function (merchantOptions) {

        var self = this;

        writeMessage.call(self, "Setting up library...");

        // Override with merchant options
        setOptions.call(self, merchantOptions);

        // Build URL for payment pages
        self.options.iframeUrl = buildUrl.call(self);

        // Setup merchant's page based on integration type
        switch (self.options.type) {
            case 'iframe':
                setupIframe.call(self);
                break;
            case 'lightbox':
                setupLightbox.call(self);
                break;
            default:
                writeMessage.call(self, "ERROR: parameter 'type' is not a valid value");
                break;
        }
    };


    /** Builds the URL for payment pages. */
    var buildUrl = function() {

        var self = this;
        var url = decodeUrl(self.options.url);

        if (isMissing(self.options.iframeIntegrationId)) {
            writeMessage.call(self, 'ERROR: iframe integration id is missing');
        }

        if (isMissing(self.options.iframeHelperURL)) {
            writeMessage.call(self, 'ERROR: iframe helper url is missing');
        }

        if (isMissing(self.options.iframeBaseURL)) {
            writeMessage.call(self, 'ERROR: iframe base url is missing');
        }

        // Use iframe app instead
        url = url.replace("/hpp/", "/hpp-iframe/");

        // Build query-string parameters
        url = addUrlParam(url, 'iframeIntegrationId', self.options.iframeIntegrationId);
        url = addUrlParam(url, 'iframeHelperURL', self.options.iframeHelperURL);
        url = addUrlParam(url, 'iframeBaseURL', self.options.iframeBaseURL);

        url = addUrlParam(url, 'language', self.options.language);
        url = addUrlParam(url, 'country', self.options.country);
        url = addUrlParam(url, 'preferredPaymentMethod', self.options.preferredPaymentMethod);

        // Build result URLs
        url = addUrlParam(url, 'successURL', self.options.successURL);
        url = addUrlParam(url, 'cancelURL', self.options.cancelURL);
        url = addUrlParam(url, 'failureURL', self.options.failureURL);
        url = addUrlParam(url, 'pendingURL', self.options.pendingURL);
        url = addUrlParam(url, 'errorURL', self.options.errorURL);

        writeMessage.call(self, 'url set to: ' + url);

        return url;

    };

    /** Check if a string is null/empty */
    var isMissing = function(str){
        return (!str || 0 === str.length);
    };

    /** Removes XML/XHTML encoding from url */
    function decodeUrl(url) {
        if(isMissing(url)){
            return url;
        }else {
            return url.replace(/&amp;/g,'&');
        }
    }

    /** Add a URL parameter if one isn't already present (and the value is non empty) */
    var addUrlParam = function(url, name, value) {
        if(isMissing(value) || isMissing(name)) {
            return url;
        } else {
            var paramPattern = new RegExp('[?&]'+name+'=');
            var paramMatch = url.search(paramPattern);
            if(paramMatch === -1) {
                return url + '&' + name + '=' + encodeURIComponent(value);
            } else {
                /* if the param is empty then remove it otherwise use it */
                var nonEmptyParamPattern = new RegExp('[?&]'+name+'=[^&]');
                var nonEmptyParamMatch = url.search(nonEmptyParamPattern);
                if(nonEmptyParamMatch === -1) {
                    return url.replace(paramPattern, '');
                } else {
                    return url;
                }
            }

        }
    }

    /* Used to override options with those specified by merchant. */
    var setOptions = function (merchantOptions) {

        var self = this;

        // Iterate new options
        for (var newProperty in merchantOptions) {
            if (self.options.hasOwnProperty(newProperty)) {
                self.options[newProperty] = merchantOptions[newProperty];
            }
        }

        // Build name of target we're controlling
        self.wpName += '-';
        self.wpName += self.options.target;

        writeMessage.call(self, "Overriding options with the following:");
        writeMessage.call(self, JSON.stringify(self.options));
    };

    /* Sets up iframe integration. */
    var setupIframe = function() {
        var self = this;

        writeMessage.call(self, "Setting up iframe...");

        // Setup messaging
        messagingSetup.call(self);

        // Inject iframe
        injectIframe.call(self);
    };

    /* Injects iframe into merchant's page, into target. */
    var injectIframe = function() {
        var self = this;

        var target = document.getElementById(self.options.target);
        writeMessage.call(self, 'Injecting iframe into page...');

        if(typeof(target) !== 'undefined' && target !== null) {
            self.iframeTitleAndLanguage = getIframeTitleAndLanguageCode.call(self);

            // Build injection function
            self.onloadInject = function() {
                injectIframeToTarget.call(self);
            };

            // Inject iframe
            if (self.options.inject === 'immediate') {
                injectIframeToTarget.call(self);
            } else if (self.options.inject === 'onload') {

                if (window.addEventListener) {
                    writeMessage.call(self, 'The browser supports addEventListener');
                    window.addEventListener('load', self.onloadInject, false);
                } else if (window.attachEvent) {
                    writeMessage.call(self, 'The  browser supports attachEvent');
                    window.attachEvent('onload', self.onloadInject);
                } else {
                    writeMessage.call(self, 'ERROR: the  browser does not support an onload event-handler');
                }

            } else if (self.options.inject === 'default') {

                window.onload = function (e) {
                    injectIframeToTarget.call(self);
                    // Detect fake load event by checking event was not raised by document
                    // -- Remove the below lines if manually editing SDK
                    if (e && e.target && e.target != document) {
                        self.isFakeLoadEvent = true;
                    }
                };

            } else {
                writeMessage.call(self, 'ERROR: accepted parameters are immediate, onload, default');
            }

        } else {
            writeMessage.call(self, "ERROR: HTML target, specified by 'target' parameter, could not be found - target: " + self.options.target);
        }
    };

    // Set injection function
    var injectIframeToTarget = function() {
        var self = this;

        var target = document.getElementById(self.options.target);
        target.innerHTML = "<div id='" + self.prefix + "'><iframe class='" + self.prefix + "-iframe' title='" + self.iframeTitleAndLanguage.title + "' id='" + self.wpName + "-iframe' src='" + self.options.iframeUrl + "' allowtransparency='yes' scrolling='no' frameBorder='0' border='0'></iframe></div>";
    };

    /*
    * Returns an object containing the language code and the page title properly translated
    * if the language code is missing or if it has a wrong value, then it defaults to english
    */
    var getIframeTitleAndLanguageCode = function() {
        var self = this;

        var defaultLanguageCode = "en";
        var titleLanguageRow = {
            "language" : self.options.language,
            "title" : self.iframeTitlesLanguageMap[self.options.language]
        };

        //if the language is not correctly passed or if there isn't a translation for the passed language code
        //then default to english
        if (isMissing(titleLanguageRow.language) || isMissing(titleLanguageRow.title)) {
            titleLanguageRow.language = defaultLanguageCode;
            titleLanguageRow.title = self.iframeTitlesLanguageMap[defaultLanguageCode];

            writeMessage.call(self, "WARN: language '" + self.options.language + "'not found for parameter 'language', using default instead...");
        }

        return titleLanguageRow;
    };

    /* Sets up lightbox integration. */
    var setupLightbox = function() {
        var self = this;

        // Validate lightbox args
        var valid = true;
        writeMessage.call(self, "Setting up lightbox...");

        if (checkNumber(self.options.lightboxMaskOpacity)){
            writeMessage.call(self, "ERROR: parameter 'lightboxMaskOpacity' is NaN: " + self.options.lightboxMaskOpacity);
            valid = false;
        }

        // Only bind lightbox if valid...
        if (valid){
            // Setup messaging
            messagingSetup.call(self);

            // Bind lightbox
            bindLightbox.call(self);
        }
    };

    /* Add binding to merchant's page to trigger lightbox. */
    var bindLightbox = function() {
        var self = this;

        // Fetch item to be binded
        var btnCheckout = document.getElementById(self.options.trigger);

        writeMessage.call(self, "Binding lightbox...");

        //check trigger button exists
        if (typeof(btnCheckout) !== 'undefined' && btnCheckout !== null) {

            btnCheckout.onclick = function() {
                injectLightbox.call(self);
                return false;
            };

            writeMessage.call(self, "Binded lightbox");

        } else {
            writeMessage.call(self, "ERROR: lightbox trigger (element) could not be found - trigger: " + self.options.trigger);
        }

    };

    /* Inject lightbox into merchant's page. */
    var injectLightbox = function() {
        var self = this;
        var target = document.getElementById(self.options.target);

        writeMessage.call(self, "Injecting lightbox...");

        // Check target exists in DOM...
        if (typeof(target) !== 'undefined' && target !== null) {

            // Inject lightbox HTML...
            var iframeTitleAndLanguage = getIframeTitleAndLanguageCode.call(self);

            var lightboxIframe =  '<div id="' + self.prefix + '">';

            lightboxIframe += '<div id="' + self.prefix + '-mask" style="background: ' + self.options.lightboxMaskColor + '; -ms-filter: \'progid:DXImageTransform.Microsoft.Alpha(Opacity='+ self.options.lightboxMaskOpacity +')\'; filter:alpha(opacity='+ self.options.lightboxMaskOpacity +'); opacity: '+ percentToDecimal(self.options.lightboxMaskOpacity) +';"></div>';
            lightboxIframe += '<div role="dialog" style="margin: 0 0 0 -' + (self.lightboxWidth/2) + 'px; width:' + self.lightboxWidth + 'px; " id="' + self.prefix + '-lightbox">';
            lightboxIframe += '<div id="' + self.wpName+ '" style="">';

            lightboxIframe +=   "<iframe onload='WPCL.focusElement(this);' " +
                                "class='" + self.prefix + "-iframe' " +
                                "title='" + iframeTitleAndLanguage.title + "' " +
                                "id='" + self.wpName + "-iframe' " +
                                "src='" + self.options.iframeUrl + "' " +
                                "allowtransparency='yes' scrolling='no' frameBorder='0' border='0'></iframe>";

            lightboxIframe += '</div></div></div>';

            target.innerHTML = lightboxIframe;

            // Bind accessibility...
            if (self.options.accessibility) {
                bindLightboxAccessibility.call(self);
            }

            // Scroll to top of page...
            scrollPage(0);

        } else {
            writeMessage.call(self, "ERROR: HTML target, specified by 'target' parameter, could not be found - target: " + self.options.target);
        }

    };

    /* Binds accessibility changes. */
    var bindLightboxAccessibility = function() {

        var self = this;

        var tags = ['a', 'input', 'select'];
        var target = document.getElementById(self.options.target);

        writeMessage.call(self, 'Setting accessibility features');

        // Loop all specified tag groups and disable tabbing
        for (var i = 0; i < tags.length; i++) {

            var tagRemove = document.getElementsByTagName(tags[i]);

            // Loop tag children
            for (var a = 0; a < tagRemove.length; a++) {

                // Set tabindex to non selectable
                tagRemove[a].tabIndex = -1;

            }
        }

        // Enable for lightbox content
        for (var b = 0; b < tags.length; b++) {

            var tagAdd = target.getElementsByTagName(tags[b]);

            // Loop tag children
            for (var c = 0; c < tagAdd.length; c++) {

                // Set tabindex to non selectable
                tagAdd[c].removeAttribute('tabindex');

            }

        }
    };

    /* Remove accessibility changes to page and lightbox. */
    var removeLightboxAccessibility = function(){
        var tags = ['a', 'input', 'select'];

        writeMessage.call(self, "Removing accessibility changes...");

        //loop all specified tag groups and disable tabbing
        for (var i = 0; i < tags.length; i++) {
            var tagName = document.getElementsByTagName(tags[i]);

            //loop tag children
            for (var a = 0; a < tagName.length; a++) {

                //set tabindex to non selectable
                tagName[a].removeAttribute('tabindex');
            }
        }

    };

    /* Removes lightbox HTML. */
    var destroyLightbox = function() {

        var self = this;

        var lb = document.getElementById(self.prefix);
        var trigger = document.getElementById(self.options.trigger);

        writeMessage.call(self, "Destroying lightbox...");

        // Remove light-box HTML
        lb.parentNode.removeChild(lb);

        // Reset accessibility changes
        if (self.options.accessibility) {
            removeLightboxAccessibility.call(self);
            trigger.focus();
        }
    };

    var destroyIframe = function() {
        var self = this;

        // removing the iframe
        var target = document.getElementById(self.options.target);
        target.innerHTML = '';

        // removing the event handlers
        if (self.options.inject === 'onload') {
            if (window.removeEventListener) {
                window.removeEventListener('load', self.onloadInject, false);
            } else if (window.attachEvent) {
                window.detachEvent('onload', self.onloadInject);
            } else {
                writeMessage.call(self, 'ERROR: the  browser does not support an onload event-handler');
            }
        }

    };

    var destroy = function() {
        var self = this;

        if (self.options.type === 'iframe') {
            // destroys the iframe
            destroyIframe.call(self);
        } else if (self.options.type === 'lightbox') {
            // destroys the lightbox
            destroyLightbox.call(self);
        } else {
            writeMessage.call(self, 'ERROR: accepted types are lightbox, iframe');
        }
    };

    /* Resizes the integration iframe, which is displaying payment pages. */
    var resize = function (height, isPostMessage) {
        var self = this;
        var iframe = getIframe.call(self);

        // Check we have iframe and message is not from helper file when post message is working...
        // -- Helper file can have longer round-trip than post message, hence old messages comes after newer post message
        if (iframe != null) {

            if (isPostMessage || !self.isPostMessage) {

                // Change height of iframe
                iframe.style.height = parseInt(height) + 'px';

                writeMessage.call(self, "iframe resized - height: " + height);

                // Adjust light-box container (light-box integration only)
                if (self.options.type === 'lightbox') {
                    var body = document.body;
                    var html = document.documentElement;

                    var pageHeight = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight);

                    if (pageHeight < height) {
                        //we need to set the height to stop chopping off the bottom
                        document.body.style.height = (parseInt(height)) + "px";
                        writeMessage.call(self, "lightbox container resized - height: " + height);
                    }
                }

            } else {
                writeMessage.call(self, "WARN: iframe not found for height resize");
            }

        } else {
            writeMessage.call(self, "WARN: iframe not found for height resize");
        }
    };

    var getIframe = function () {
        var self = this;

        var targetName = self.wpName + "-iframe";
        var iframe = document.getElementById(targetName);
        if (iframe == null) {
            writeMessage.call(self, "WARN - unable to find iframe - target name: " + targetName);
        }

        return iframe;
    };

    /* Full-page redirect to the specified URL. */
    var redirect = function(url) {
        window.location.replace(url)
    };

    /* Convert a percentage to a decimal. */
    var percentToDecimal = function(percent) {
        return percent / 100;
    };

    /* Check a value is a number. */
    var checkNumber = function(val) {
        if(typeof(val) === 'string'){
            return true;
        }

        return isNaN(val);
    };

    /* Write a message to the console. */
    var writeMessage = function(msg){

        var self = this;
        if (self && self.options && self.options.debug && console && console.log) {
            console.log("Worldpay HPP JavaScript SDK - " + msg);
        }
    };

    /* Handles autoscrolling for buttons */
    var scroll = function(currencyFormOffset){
        var self = this;

        switch (self.options.type) {
            case 'lightbox':
                if (currencyFormOffset) {
                    scrollPage(currencyFormOffset);
                    writeMessage.call(self, "scrolled to top of lightbox currency conversion form.");
                } else {
                    scrollPage(0);
                    writeMessage.call(self, "scrolled to top of lightbox.");
                }
                break;
            case 'iframe':
                var iframe = getIframe.call(self);
                if (currencyFormOffset) {
                    scrollPage(currencyFormOffset + iframe.offsetTop);
                    writeMessage.call(self, "scrolled to top of iframe currency conversion form.");
                } else {
                    scrollPage(iframe.offsetTop);
                    writeMessage.call(self, "scrolled to top of iframe.");
                }
                break;
            default:
                writeMessage.call(self, "Integration type is not correct.");
                break;
        }
    };

    /* Scrolls.. */
    var scrollPage = function(offsetValue) {
        document.body.scrollTop = offsetValue;
        document.documentElement.scrollTop = offsetValue;
    };

    /*
        Client-side Messaging
        ****************************************************************************************************************
     */

    /* Sets up JS messaging, so that messages can be passed between this script and the payment-pages in the iframe. */
    var messagingSetup = function () {
        var self = this;

        var handler = function (event) {
            messagingHandleMessage.call(self, event);
        };

        if (window.addEventListener) {
            window.addEventListener("message", handler, false);
        } else {
            window.attachEvent("onmessage", handler);
        }
    };

    /* Handles a global JS message, although we're only interested in those from payment-pages. */
    var messagingHandleMessage = function (event) {

        var self = this;

        // Set flag to indicate post-message mechanism is working
        this.isPostMessage = true;

        // Verify source is same as iframe; we can get source to confirm this...
        var origin = event.origin || event.originalEvent.origin;
        var iframe = getIframe.call(self);

        // Block request if unknown source, unless debugging is switched on...
        var iframeUrl = (iframe != null && iframe.src != null ? iframe.src : null);

        if (iframeUrl != null && iframeUrl.indexOf(origin) != 0) {
            writeMessage.call(self, "WARN - post-message from different source - origin: " + origin + ", iframe: " + iframeUrl);

            if (!self.options.debug) {
                return;
            }
        }

        var data;

        // Attempt to parse - this is to support older browsers
        try {
            data = JSON.parse(event.data);
        } catch (e) {
            data = null;
        }

        // Just to avoid catching other potential messages...
        if (data != null && data.source == "hpp" && data.action != null && data.args != null) {

            /*
                Check library object is same, to avoid conflicts. But if null, the payment page instance has lost
                the session, so the message can continue (as its hit a worst case already). Almost all integrations
                will only have a single instance.
             */

            if (data.id != null && data.id.length > 0 && data.id != self.options.iframeIntegrationId) {
                writeMessage.call(self, "ignoring message as different instance - req: " + data.id + ", ours: " + self.options.iframeIntegrationId);
            } else {
                switch (data.action) {
                    case "check":
                        messagingHandleMessageCheck.call(self);
                        break;
                    case "resize":
                        messagingHandleMessageResize.call(self, data);
                        break;
                    case "scroll":
                        messagingHandleMessageScroll.call(self, data);
                        break;
                    case "result":
                        messagingHandleResultCallback.call(self, data);
                        break;
                    default:
                        writeMessage.call(self, "unhandled action: " + data.action);
                        break;
                }
            }

        } else {
            writeMessage.call(self, "malformed post-message received - " + JSON.stringify(data));
        }
    };

    var messagingHandleMessageCheck = function () {
        var self = this;

        writeMessage.call(self, "received postMessage mechanism check, replying back");

        // Build SDK info
        var sdkInfo = buildSdkInfo.call(self);

        // Build response
        var data = {
            "source" : "hpp",
            "action" : "check-working",
            "sdkInfo" : sdkInfo
        };
        var payload = JSON.stringify(data);

        var iframe = getIframe.call(self);
        if (iframe != null && iframe.contentWindow && iframe.contentWindow.postMessage) {
            iframe.contentWindow.postMessage(payload, "*");
        } else {
            writeMessage.call(self, "WARN: cannot reply back, iframe not found");
        }
    };

    /* Handles request from payment-pages to resize the iframe. */
    var messagingHandleMessageResize = function (data) {
        var self = this;

        var height = data.args.height;
        writeMessage.call(self, "resizing iframe... - height: " + height);

        resize.call(self, height, true);
    };

    /* Handles request from payment-pages to scroll payments page into view. */
    var messagingHandleMessageScroll = function (data) {
        var self = this;

        var currencyFormOffset = data.args.scrollingOffset;

        writeMessage.call(self, "scrolling payments page into view");

        scroll.call(self, currencyFormOffset);
    };

    /* Handles JSON result and passes it to a merchant-provided callback function. */
    var messagingHandleResultCallback = function(data) {
        var self = this;

        // Fetch result callback
        var result = data.args.result;

        // Invoke merchant callback
        var callback = self.options.resultCallback;

        if (callback == null) {
            writeMessage.call(self, "no result callback function specified, skipping callback invocation");
        } else if (result == null) {
            writeMessage.call(self, "null result from payment pages, skipping callback invocation");
        } else {
            writeMessage.call(self, "invoking result callback");
            callback(result);
        }
    };

    var buildSdkInfo = function() {
        var self = this;
        var sdkInfo;

        if (!self.sdkInfoAlreadySent) {

            // Collect information
            var version = "12.2";
            var saved = isLibrarySaved.call(self);
            var integrationType = self.options.type;
            var insideFrame = isInsideFrame.call(self);
            var parentCrossDomain = isParentDomainDifferent.call(self);
            var manualOnload = isManualOnloadIframe.call(self);
            var isCallback = (self.options.resultCallback != null);
            var injectionType = self.options.inject;

            // Build result
            sdkInfo = {
                "version": version,
                "saved" : saved,
                "integrationType": integrationType,
                "insideFrame": insideFrame,
                "parentCrossDomain": parentCrossDomain,
                "manualOnload": manualOnload,
                "debug" : self.options.debug,
                "callback" : isCallback,
                "inject": injectionType
            };

            // Update flag
            self.sdkInfoAlreadySent = true;

        } else {
            sdkInfo = {
                "alreadySent" : "true"
            };
        }

        return sdkInfo;
    };

    var isInsideFrame = function() {
        try {
            var test = top != window;
            return test;
        } catch (e) {
            return true;
        }
    };

    /* Detects if the parent of the current page is a different domain */
    var isParentDomainDifferent = function() {
        try {
            var test = parent != null && parent.document;
            return !test;
        } catch (e) {
            return true;
        }
    };

    /* Determines if onload event was manually raised for iframe */
    var isManualOnloadIframe = function() {
        var self = this;
        var result = false;

        if (self.options.type == "iframe") {
            result = self.isFakeLoadEvent;
        }

        return result;
    };

    /* Detects if a copy of the library has been saved */
    var isLibrarySaved = function() {
        var result = true;

        var scripts = document.getElementsByTagName("script");
        var script, url;

        for (var i = 0; result && i < scripts.length; i++) {
            script = scripts[i];
            url = script.src;
            if (url != null && url.indexOf(".worldpay") > 0) {
                result = false;
            }
        }

        return result;
    };

    /* Exposed functions */
    return {
        setup: setup,
        destroy: destroy,
        resize: resize,
        redirect: redirect,
        scroll: scroll
    };

}());

// Focus specified element if not focused already; uses setTimeout due to Firefox quirk
WPCL.focusElement = function (element) {
    if (document.activeElement != element) {
        setTimeout(function () {
            element.focus();
        }, 0);
    }
};