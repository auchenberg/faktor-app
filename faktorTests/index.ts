import {
  app,
  Tray,
  Menu,
  Notification,
  clipboard,
  nativeImage,
} from "electron";
import { optimizer } from "@electron-toolkit/utils";
import iconTay from "../../resources/tray.png?asset";
import { getRecentTextsWithCodes, openDatabase } from "./utils/imessage";
import { askForFullDiskAccess } from "node-mac-permissions";
import { WebSocketServer } from "ws";

let previousMostRecentText = null;
let wss = null;

app.dock.hide();

app.whenReady().then(async () => {
  console.log("booting...");

  const icon = nativeImage
    .createFromPath(iconTay)
    .resize({ width: 16, height: 16 });

  let appIcon = new Tray(icon);
  appIcon.setToolTip("Autho!");

  const contextMenu = buildMenu();
  appIcon.setContextMenu(contextMenu);

  app.on("browser-window-created", (_, window) => {
    optimizer.watchWindowShortcuts(window);
  });

  try {
    console.log("ready");

    // Try to open the database
    await openDatabase();

    // Update the menu bar with recent texts
    fetchTexts(appIcon);

    // Call the updateMenuBar function every 5 seconds
    setInterval(() => fetchTexts(appIcon), 5000);

    // Start Websocket Server
    startWebsocketServer();
  } catch (error: any) {
    console.error("... error occured:", error.message);

    if (error.message.includes("SQLITE_CANTOPEN")) {
      console.error("Can't open database. Requesting full disk access...");
      askForFullDiskAccess();
    }
  }
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

// Function to update menu bar with recent texts
async function fetchTexts(appIcon: Tray) {
  console.log("Fetching texts...");
  // Get recent texts
  let texts = await getRecentTextsWithCodes();
  let mostRecentText = texts[0]; // Assume the first text is the most recent

  if (
    mostRecentText &&
    previousMostRecentText &&
    mostRecentText.guid != previousMostRecentText.guid
  ) {
    handleNewText(mostRecentText);
  }
  previousMostRecentText = mostRecentText;

  // Update menu bar
  let codes = texts.map((text) => {
    return {
      code: `${text.code}`,
      label: `${text.code} (from ${text.sender})`,
    };
  });

  const contextMenu = buildMenu(codes);
  appIcon.setContextMenu(contextMenu);
}

const handleNewText = (text) => {
  console.log("New text:", text.guid);
  showNotification(text);
  sendPush(text);
};

const showNotification = (text) => {
  console.log("Showing notification for new text:", text);
  let notification = new Notification({
    title: `Autho`,
    body: `New authentication code ${text.code} from ${text.sender}`,
    urgency: "critical",
    actions: [
      {
        type: "button",
        text: "Copy code",
      },
    ],
  });

  const onClick = () => {
    console.log("Writing code to clipboard", text.code);
    clipboard.writeText(text.code);
  };

  notification.on("click", onClick);
  notification.on("action", onClick);
  notification.show();
};

const sendPush = (text) => {
  console.log("Sending push for new text:", text);

  if (wss) {
    wss.clients.forEach(function each(client) {
      client.send({
        type: "new-code",
        data: {
          code: text.code,
          sender: text.sender,
        },
      });
    });
  }
};

function buildMenu(
  codes: Array<{ label: string; code: string }> = [
    { label: "Loading...", code: "" },
  ]
) {
  const submenuItems = codes.map((item) => ({
    label: `${item.label}`,
    type: "normal",
    click: () => {
      clipboard.writeText(item.code);
    },
  }));

  return Menu.buildFromTemplate([
    {
      label: "Recent codes",
      type: "submenu",
      submenu: submenuItems,
    },
    { label: "", type: "separator" },
    {
      label: "Preferences",
      type: "submenu",
      submenu: [
        { label: "Show notifications", type: "checkbox", checked: true },
        {
          label: "Enable browser integration",
          type: "checkbox",
          checked: true,
        },
      ],
    },
    { label: "", type: "separator" },
    { label: "Autho v1.0.0", type: "normal", enabled: false },
    { label: "Install Chrome extension", type: "normal" },
    { label: "", type: "separator" },
    { label: "Quit", type: "normal", role: "quit" },
  ]);
}

const startWebsocketServer = () => {
  console.log("Starting websocket server...");
  wss = new WebSocketServer({ port: 9000 });

  wss.on("connection", function connection(ws, req) {
    const ip = req.socket.remoteAddress;
    console.log("New connection from", ip);

    ws.on("error", console.error);

    // // Block all connections except localhost
    // ::1 or "127.0.0.1

    // if (req.socket.remoteAddress !== "127.0.0.1") {
    //   res.send("403 Access Denied");
    //   res.end();
    // } else {
    //   // allow access
    // }

    ws.on("message", function incoming(message) {
      console.log("received: %s", message);
    });

    ws.send(JSON.stringify({ status: "connected" }));
  });
};
