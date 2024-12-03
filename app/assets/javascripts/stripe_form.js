function loadStripeProcessor(pub_key, form_id, submit_button_id) {
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
		type: 'POST',
		url: form_element.attr('action'),
		data: formData + "&client[card_token]=" + token.id
	});
}
