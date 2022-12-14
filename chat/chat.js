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
  // construct API request URL
  let url = 'http://127.0.0.1:8000/answer?question=' + encodeURIComponent(input);
  // fetch the API response
  //   per https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Client-side_web_APIs/Fetching_data
  // decided against axios because trouble getting required() to work without npm:
  //   https://rapidapi.com/blog/how-to-use-an-api-with-javascript/
  fetch(url)
  .then((response) => {
    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }
    return response.text();
  })
  .then((text) => addChatEntry(input, text) )
  .catch((error) => addChatEntry(input, `Could not fetch answer: ${error}`) );
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
    // remove opening double line breaks
    botText.innerText = `${product.replace('"\\n\\n', '"')}`;
    // could replace newlines with HTML breaks
    //botText.textContent = `${product.trim().replace(/\\n/g, '<br>')}`;
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
