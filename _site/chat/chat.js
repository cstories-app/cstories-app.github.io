//  implement an instant messaging feature into this app that will enable the user to send the message just by pressing the enter key after they finish typing the message
const inputField = document.getElementById("input")
inputField.addEventListener("keydown", function(e) {
  if (e.code === "Enter") {
    let input = inputField.value;
    inputField.value = "";
    output(input);
  }
});

function output(input){
  /*
  let product;
  // remove everything other than words, digits, and spaces
  let text = input.toLowerCase().replace(/[^\w\s\d]/gi, "");

  // remove all rogue characters and everything that could make the matches difficult
  text = text
    .replace(/ a /g, " ")
    .replace(/whats/g, "what is")
    .replace(/please /g, "")
    .replace(/ please/g, "");

  if (compare(utterances, answers, text)) {
    // Search for exact match in triggers
    product = compare(utterances, answers, text);
  } else {
    product = alternatives[Math.floor(Math.random() * alternatives.length)];
  }
    //update  DOM
  addChatEntry(input, product);
  */

  /*
  async function doGetRequest() {
    let payload = { question: input };
    const params = new url.URLSearchParams(payload);
    let res = await axios
      .get(`http://127.0.0.1:8000/answer?${params}`)
      .then(response => {
        console.log(response.data);
      })
      .catch(error => console.error(error));
  }
  doGetRequest();

  async function doGetRequest() {
    let payload = { question: input };
    const params = new url.URLSearchParams(payload);
    let res = await axios.get(`http://127.0.0.1:8000/answer?${params}`);
    let data = res.data;
    console.log(data);
  }
  doGetRequest();


  const axios = require('axios').default;

  async function getAnswer(input) {
    try {
      const response = await axios.get('http://127.0.0.1:8000/answer', {
        params: {
          question: input } });
      console.log(response);
    } catch (error) {
      console.error(error);
    }
  }

  let response = getAnswer(input);

  //update  DOM
  addChatEntry(input, response.data);
  */

  let url = 'http://127.0.0.1:8000/answer?question=' + encodeURIComponent(input);
  fetch(url)
  // fetch() returns a promise. When we have received a response from the server,
  // the promise's `then()` handler is called with the response.
  .then((response) => {
    // Our handler throws an error if the request did not succeed.
    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }
    // Otherwise (if the response succeeded), our handler fetches the response
    // as text by calling response.text(), and immediately returns the promise
    // returned by `response.text()`.
    return response.text();
  })
  // When response.text() has succeeded, the `then()` handler is called with
  // the text, and we copy it into the `poemDisplay` box.
  .then((text) => addChatEntry(input, text) )
  // Catch any errors that might happen, and display a message
  // in the `poemDisplay` box.
  .catch((error) => addChatEntry(input, `Could not fetch verse: ${error}`) );
}

function compare(utterancesArray, answersArray, string) {
  let reply;
  let replyFound = false;
  for (let x = 0; x < utterancesArray.length; x++) {
    for (let y = 0; y < utterancesArray[x].length; y++) {
      if (utterancesArray[x][y] === string) {
        let replies = answersArray[x];
        reply = replies[Math.floor(Math.random() * replies.length)];
        replyFound = true;
        break;
      }
    }
    if (replyFound) {
      break;
    }
  }
  return reply;
}

function addChatEntry(input, product) {
  const messagesContainer = document.getElementById("messages");

  let userDiv = document.createElement("div");
  userDiv.id = "user";
  userDiv.className = "user response";
  userDiv.innerHTML = `${input}`;
  messagesContainer.appendChild(userDiv);

  let botDiv = document.createElement("div");
  let botText = document.createElement("span");
  botDiv.id = "bot";
  botDiv.className = "bot response";
  botText.innerText = "Typing...";
  botDiv.appendChild(botText);
  messagesContainer.appendChild(botDiv);

  setTimeout(() => {
    botText.innerText = `${product}`;
    // try to replace newlines with HTML breaks
    //botText.textContent = `${product.replace(/\\n/g, '<br>')}`;
  }, 2000);
}

// adding the DOMContentLoaded listener here is ensuring that the JavaScript will load only when the HTML has finished rendering
document.addEventListener("DOMContentLoaded", () => {
  document.querySelector("#input").addEventListener("keydown", function(e) {
    if (e.code === "Enter") {
      console.log("You pressed the enter button!")
    }
  });
});

const utterances = [
  ["how are you", "how is life", "how are things"],                          //0
  ["hi", "hey", "hello", "good morning", "good afternoon"],                  //1
  ["what are you doing", "what is going on", "what is up"],                  //2
  ["how old are you"],					                                             //3
  ["who are you", "are you human", "are you bot", "are you human or bot"],   //4
];

// Possible responses corresponding to triggers
const answers = [
  [
    "Fine... how are you?",
    "Pretty well, how are you?",
    "Fantastic, how are you?"
  ],                                                //0
  [
    "Hello!", "Hi!", "Hey!", "Hi there!", "Howdy"
  ],						                                    //1
  [
    "Nothing much",
    "About to go to sleep",
    "Can you guess?",
    "I don't know actually"
  ],						                                    //2
  ["I am infinite"],					                      //3
  ["I am just a bot", "I am a bot. What are you?"],	//4
];

// For any other user input
 const alternatives = [
  "Go on...",
  "Try again",
];


