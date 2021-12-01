import * as Turbo from "https://cdn.skypack.dev/pin/@hotwired/turbo@v7.0.1-PTwzYYo5FVYxpdtkOcWe/mode=imports,min/optimized/@hotwired/turbo.js";

const visibleP = "p.content";
let counter = 0;
async function start() {
  let nextButton = document.getElementById("next");
  attachInputListeners(nextButton);

  if (nextButton) {
    nextButton.addEventListener("click", async (event) => {
      event.preventDefault();
      let text = document
        .querySelector(visibleP)
        .innerText.replace(/\n(.+?)\n/g, "$1");

      submitAndRedirect(text);
    });
  }

  let spinner = document.getElementById("spinner");
  if (spinner) {
    generateText();
  }
}

async function submitAndRedirect(text) {
  let form = document.createElement("form");
  form.action = "/submit";
  form.method = "POST";

  form.innerHTML = `<input name="text" value="${text}">`;

  document.body.append(form);

  form.submit();
}

async function generateText() {
  let prompt = document.getElementById("prompt").innerText;
  let resultJson = await postData(`/generate`, { prompt: prompt });
  const text = resultJson.result;

  document.getElementById("text").innerHTML = text;
  document.getElementById("spinner-holder").classList.add("is-hidden");

  let againButton = document.getElementById("again");
  againButton.classList.remove("is-hidden");
  againButton.addEventListener("click", function (event) {
    window.location.href = "/";
  });
}

function attachInputListeners(nextButton) {
  const visibleInputs = getVisibleInputs();

  if (visibleInputs.length > 0) {
    visibleInputs.forEach((input) => {
      input.addEventListener("input", function (event) {
        let span = input.nextElementSibling;
        span.innerHTML = this.value.replace(/\s/g, "&nbsp;");
        this.style.width = `${span.offsetWidth + 10}px`;
        checkInputs(nextButton);
      });
    });
  }
}

async function postData(url, data) {
  let response = await fetch(url, {
    method: "POST",
    body: JSON.stringify(data),
  });

  if (response.ok) {
    return await response.json();
  } else {
    console.error("HTTP-Error: " + response.status);
    return {};
  }
}

function checkInputs(nextButton) {
  const visibleInputs = getVisibleInputs();
  const allSet = visibleInputs.every((input) => {
    let inputSet = input.value.length > 0;
    inputSet
      ? input.classList.add("entered")
      : input.classList.remove("entered");
    return inputSet;
  });

  if (allSet) {
    nextButton.removeAttribute("disabled");
  } else {
    nextButton.setAttribute("disabled", "disabled");
  }
}

function getVisibleInputs() {
  return Array.prototype.slice.call(
    document.querySelectorAll(`${visibleP} input`)
  );
}

window.addEventListener("DOMContentLoaded", start);
