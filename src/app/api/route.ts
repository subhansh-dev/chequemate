import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    name: "Synesthesia",
    status: "ok",
    version: "0.2.1",
    time: new Date().toISOString(),
  });
}