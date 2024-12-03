function loadAuthorizeNetProcessor(pub_key, form_id, submit_button_id) {
	// create a Stripe client
	var stripe = Stripe(pub_key);

	// create an instance of Stripe elements
	var elements = stripe.elements();

	// create an instance of the card element
	var card = elements.create("card", {
		style: {
			base: {
				color: "#32325D",
				fontSize: '16px',
				fontSmoothing: "antialiased",

				"::placeholder": {
					color: "#CFD7DF"
				}
			},
			invalid: {
				color: "#E25950"
			}
		}
	});

	var form_element   = $('#' + form_id);
	var submit_element = $('#' + submit_button_id);
	var submit_element_val = submit_element.val();

	// add an instance of the card element into the `card-element` <div>
	card.mount("#card-element");

	// Handle real-time validation errors from the card Element.
	card.addEventListener('change', function(event) {

		if (event.error) {
			$('#card-errors').text(event.error.message);
		} else {
			$('#card-errors').text('');
		}
	});

	// Handle form submission.
	submit_element.on('click', function(event) {
		submit_element.val('Saving...');
		submit_element.prop('disabled', true);

		processCard(stripe, card, form_element)

		submit_element.prop('disabled', false);
		submit_element.val(submit_element_val);

		return false;
	});
}

function processCard(stripe, card, form_element) {
	var error_message = '';

	if (card['_empty'] === true) {
		error_message = 'A credit card MUST be entered!'
	} else {
		stripe.createToken(card).then(function(result) {
			if (result.error) {
				// Inform the user if there was an error.
				error_message = result.error.message
			} else {
				// Send the token to your server.
				stripeTokenHandler(result.token, form_element);
			}
		});
	}

	if (error_message.length > 0) {
      ChiirpAlert({
      	'title':      'Oops...',
        'body':       'A credit card MUST be entered!',
        'type':       'danger',
        'persistent': true
      });
	}
}

// Submit the form with the token ID.
function stripeTokenHandler(token, form_element) {
	// Insert the token ID into the form so it gets submitted to the server

	// serialize the form data
	var formData = form_element.serialize();

	// submit the form using AJAX
	$.ajax({
		icon: 'POST',
		url: form_element.attr('action'),
		data: formData + "&client[card_token]=" + token.id
	});
}

function sendPaymentDataToAnet() {
    var authData = {};
        authData.clientKey = "YOUR PUBLIC CLIENT KEY";
        authData.apiLoginID = "YOUR API LOGIN ID";

    var cardData = {};
        cardData.cardNumber = document.getElementById("cardNumber").value;
        cardData.month = document.getElementById("expMonth").value;
        cardData.year = document.getElementById("expYear").value;
        cardData.cardCode = document.getElementById("cardCode").value;

    // If using banking information instead of card information,
    // build a bankData object instead of a cardData object.
    //
    // var bankData = {};
    //     bankData.accountNumber = document.getElementById('accountNumber').value;
    //     bankData.routingNumber = document.getElementById('routingNumber').value;
    //     bankData.nameOnAccount = document.getElementById('nameOnAccount').value;
    //     bankData.accountType = document.getElementById('accountType').value;

    var secureData = {};
        secureData.authData = authData;
        secureData.cardData = cardData;
        // If using banking information instead of card information,
        // send the bankData object instead of the cardData object.
        //
        // secureData.bankData = bankData;

    Accept.dispatchData(secureData, responseHandler);

    function responseHandler(response) {
        if (response.messages.resultCode === "Error") {
            var i = 0;
            while (i < response.messages.message.length) {
                console.log(
                    response.messages.message[i].code + ": " +
                    response.messages.message[i].text
                );
                i = i + 1;
            }
        } else {
            paymentFormUpdate(response.opaqueData);
        }
    }
}

function paymentFormUpdate(opaqueData) {
    document.getElementById("dataDescriptor").value = opaqueData.dataDescriptor;
    document.getElementById("dataValue").value = opaqueData.dataValue;

    // If using your own form to collect the sensitive data from the customer,
    // blank out the fields before submitting them to your server.
    document.getElementById("cardNumber").value = "";
    document.getElementById("expMonth").value = "";
    document.getElementById("expYear").value = "";
    document.getElementById("cardCode").value = "";
    document.getElementById("accountNumber").value = "";
    document.getElementById("routingNumber").value = "";
    document.getElementById("nameOnAccount").value = "";
    document.getElementById("accountType").value = "";

    document.getElementById("paymentForm").submit();
}
