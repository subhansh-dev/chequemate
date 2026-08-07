import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { db } from "@/lib/db";

export const runtime = "nodejs";

const FeedbackSchema = z.object({
  name: z.string().trim().min(1, "Name is required").max(40, "Keep it under 40 characters"),
  role: z.string().trim().max(40, "Keep it under 40 characters").optional().nullable(),
  message: z.string().trim().min(3, "A little more detail, please").max(600, "Keep it under 600 characters"),
  rating: z.number().int().min(1).max(5).optional().nullable(),
});

export async function GET() {
  try {
    const items = await db.feedback.findMany({
      orderBy: { createdAt: "desc" },
      take: 50,
      select: {
        id: true,
        name: true,
        role: true,
        message: true,
        rating: true,
        createdAt: true,
      },
    });
    return NextResponse.json({ items });
  } catch (error) {
    console.error("GET /api/feedback failed:", error);
    return NextResponse.json(
      { error: "The feedback database is temporarily unavailable. Please try again shortly." },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be valid JSON." }, { status: 400 });
  }

  const parsed = FeedbackSchema.safeParse(body);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    return NextResponse.json(
      { error: first?.message ?? "Invalid input.", issues: parsed.error.issues },
      { status: 400 }
    );
  }

  try {
    const created = await db.feedback.create({
      data: {
        name: parsed.data.name,
        role: parsed.data.role ?? null,
        message: parsed.data.message,
        rating: parsed.data.rating ?? null,
      },
      select: {
        id: true,
        name: true,
        role: true,
        message: true,
        rating: true,
        createdAt: true,
      },
    });
    return NextResponse.json({ item: created }, { status: 201 });
  } catch (error) {
    console.error("POST /api/feedback failed:", error);
    return NextResponse.json(
      { error: "We couldn't save your note. The database may be offline." },
      { status: 500 }
    );
  }
}