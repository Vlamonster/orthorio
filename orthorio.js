(async function() {
  const userData = await MiniZincIDE.getUserData();

  const tileWidth = 32;
  const tileHeight = 32;

  const totalWidth = userData.width * tileWidth;
  const totalHeight = userData.height * tileHeight;

  const svg = document.querySelector("svg");
  const grid = svg.querySelector(".grid");
  const background = svg.querySelector(".background");

  svg.setAttribute("viewBox", `0 0 ${totalWidth} ${totalHeight}`);
  svg.setAttribute("width", totalWidth);
  svg.setAttribute("height", totalHeight);

  for (let y = 0; y < userData.height; y++) {
    for (let x = 0; x < userData.width; x++) {
      const grass = document.createElementNS("http://www.w3.org/2000/svg", "image");
      grass.setAttribute("href", "resources/grass.png");
      grass.setAttribute("x", x * tileWidth);
      grass.setAttribute("y", y * tileHeight);
      grass.setAttribute("width", tileWidth);
      grass.setAttribute("height", tileHeight);
      background.appendChild(grass);
    }
  }

  const imageMap = new Map();

  for (let y = 0; y < userData.height; y++) {
    for (let x = 0; x < userData.width; x++) {
      const image = document.createElementNS("http://www.w3.org/2000/svg", "image");
      image.setAttribute("href", "resources/grass.png");
      image.setAttribute("x", x * tileWidth);
      image.setAttribute("y", y * tileHeight);
      image.setAttribute("width", tileWidth);
      image.setAttribute("height", tileHeight);
      imageMap.set(y * userData.width + x, image);
      grid.appendChild(image);
    }
  }

  function index(y, x) { return y * userData.width + x };

  function setSolution(data) {
    const sb = data.sb
    for (let y = 0; y < userData.height; y++) {
      for (let x = 0; x < userData.width; x++) {
        const i = index(y, x);

        const ON = sb[i].e == "SB_N";
        const OS = sb[i].e == "SB_S";
        const OW = sb[i].e == "SB_W";
        const OE = sb[i].e == "SB_E";

        const IN = 0 < y                   && (sb[index(y - 1, x    )].e == "SB_S" || sb[index(y - 1, x    )].e == "SB_TO_S4")
        const IS = y < userData.height - 1 && (sb[index(y + 1, x    )].e == "SB_N" || sb[index(y + 1, x    )].e == "SB_TO_N4")
        const IW = 0 < x                   && (sb[index(y    , x - 1)].e == "SB_E" || sb[index(y    , x - 1)].e == "SB_TO_E4")
        const IE = x < userData.width - 1  && (sb[index(y    , x + 1)].e == "SB_W" || sb[index(y    , x + 1)].e == "SB_TO_W4")

        if      (sb[i].e == "SB_None") imageMap.get(i).setAttribute("href", "resources/empty.png");
        else if (sb[i].e == "SB_Wall") imageMap.get(i).setAttribute("href", "resources/empty.png");

        else if (IN && ON) imageMap.get(i).setAttribute("href", "resources/empty.png"); // ?
        else if (IN && OS) imageMap.get(i).setAttribute("href", "resources/belt-NS.png");
        else if (IN && OW) imageMap.get(i).setAttribute("href", "resources/belt-NW.png");
        else if (IN && OE) imageMap.get(i).setAttribute("href", "resources/belt-NE.png");

        else if (IS && ON) imageMap.get(i).setAttribute("href", "resources/belt-SN.png");
        else if (IS && OS) imageMap.get(i).setAttribute("href", "resources/empty.png"); // ?
        else if (IS && OW) imageMap.get(i).setAttribute("href", "resources/belt-SW.png");
        else if (IS && OE) imageMap.get(i).setAttribute("href", "resources/belt-SE.png");

        else if (IW && ON) imageMap.get(i).setAttribute("href", "resources/belt-WN.png");
        else if (IW && OS) imageMap.get(i).setAttribute("href", "resources/belt-WS.png");
        else if (IW && OW) imageMap.get(i).setAttribute("href", "resources/empty.png"); // ?
        else if (IW && OE) imageMap.get(i).setAttribute("href", "resources/belt-WE.png");

        else if (IE && ON) imageMap.get(i).setAttribute("href", "resources/belt-EN.png");
        else if (IE && OS) imageMap.get(i).setAttribute("href", "resources/belt-ES.png");
        else if (IE && OW) imageMap.get(i).setAttribute("href", "resources/belt-EW.png");
        else if (IE && OE) imageMap.get(i).setAttribute("href", "resources/empty.png"); // ?

        else if (ON) imageMap.get(i).setAttribute("href", "resources/belt-SN.png");
        else if (OS) imageMap.get(i).setAttribute("href", "resources/belt-NS.png");
        else if (OW) imageMap.get(i).setAttribute("href", "resources/belt-EW.png");
        else if (OE) imageMap.get(i).setAttribute("href", "resources/belt-WE.png");

        else if (sb[i].e == "SB_TI_N4") imageMap.get(i).setAttribute("href", "resources/SB_TI_N4.png");
        else if (sb[i].e == "SB_TI_S4") imageMap.get(i).setAttribute("href", "resources/SB_TI_S4.png");
        else if (sb[i].e == "SB_TI_E4") imageMap.get(i).setAttribute("href", "resources/SB_TI_E4.png");
        else if (sb[i].e == "SB_TE_E4") imageMap.get(i).setAttribute("href", "resources/SB_TE_E4.png");

        else if (sb[i].e == "SB_TO_N4") imageMap.get(i).setAttribute("href", "resources/SB_TO_N4.png");
        else if (sb[i].e == "SB_TO_S4") imageMap.get(i).setAttribute("href", "resources/SB_TO_S4.png");
        else if (sb[i].e == "SB_TO_W4") imageMap.get(i).setAttribute("href", "resources/SB_TO_W4.png");
        else if (sb[i].e == "SB_TO_E4") imageMap.get(i).setAttribute("href", "resources/SB_TO_E4.png");

        else imageMap.get(i).setAttribute("href", "resources/empty.png");
      }
    }
  }

  // Visualise last solution on startup
  const numSols = await MiniZincIDE.getNumSolutions();
  if (numSols > 0) {
    const solution = await MiniZincIDE.getSolution(numSols - 1);
    setSolution(solution.data);
  }

  // Show new solutions if we're following the latest solution
  let followLatest = true;
  MiniZincIDE.on('solution', (solution) => {
    if (followLatest) {
      setSolution(solution.data);
    }
  });

  MiniZincIDE.on('goToSolution', async (index) => {
    // Requesting index -1 turns on following latest solution
    // Otherwise, we stop showing the latest solution and show the requested one
    followLatest = index === -1;
    const solution = await MiniZincIDE.getSolution(index);
    setSolution(solution.data);
  })
})();