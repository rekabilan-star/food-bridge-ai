const responses = {
    "how to donate": "To donate food, click on the 'Donate' button on the dashboard, fill in the food details, and set your location. A volunteer will pick it up.",
    "who are you": "I am FoodRescue AI, your assistant to help minimize food waste and feed the hungry.",
    "how to join as volunteer": "You can join as a volunteer by registering on the app and selecting the 'Volunteer' role. Our admin will verify your profile.",
    "is the food safe": "We encourage donors to follow hygiene standards. NGOs verify food quality during pickup using our checklist.",
    "hello": "Hello! How can I help you today with food rescue?",
    "hi": "Hi there! Looking to donate or volunteer?"
};

exports.getBotResponse = (req, res) => {
    const { message } = req.body;
    const lowerMessage = message.toLowerCase();

    let botResponse = "I'm sorry, I don't have an answer for that yet. You can contact our support at support@foodrescue.ai";

    for (const key in responses) {
        if (lowerMessage.includes(key)) {
            botResponse = responses[key];
            break;
        }
    }

    res.status(200).json({ success: true, response: botResponse });
};
