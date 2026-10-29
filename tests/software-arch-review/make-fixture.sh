#!/usr/bin/env bash
# Generates the S1 fixture repo: a brownfield single-context service with one
# seeded violation per rule (see expected-findings.md). Fresh output per run;
# the fixture is throwaway evidence, never committed.
#
# Usage: ./make-fixture.sh
# Output: /tmp/opencode/arch-review-fixture/order-service
set -euo pipefail

readonly OUTPUT_BASE="/tmp/opencode/arch-review-fixture"
readonly OUTPUT_DIR="$OUTPUT_BASE/order-service"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"/src/{application,models,models/customer,services,infrastructure,utils}

cat > "$OUTPUT_DIR/README.md" <<'EOF'
# order-service

Places orders, manages customers, computes pricing.
Single deployment; one team owns it.
EOF

cat > "$OUTPUT_DIR/src/transport.ts" <<'EOF'
import { db } from "./infrastructure/db";
import type { Request, Response } from "./types";
import { Order } from "./models/order";
import type { Cart } from "./models/cart";

// POST /orders
export async function createOrderRoute(req: Request, res: Response) {
  const cart = req.body as Cart;
  const customer = await db.customers.find(cart.customerId);

  let total = 0;
  for (const item of cart.items) {
    total += item.unitPrice * item.quantity;
  }
  if (customer.tier === "gold") {
    total *= 0.9;
  }

  const order = Order.fromCart(cart, total);
  await db.orders.insert(order);
  res.json(order);
}
EOF

cat > "$OUTPUT_DIR/src/types.ts" <<'EOF'
export interface Request {
  body: unknown;
}

export interface Response {
  json(data: unknown): void;
}
EOF

cat > "$OUTPUT_DIR/src/application/checkout.ts" <<'EOF'
import type { Cart } from "../models/cart";
import type { Order, OrderRepo } from "../models/order";

export async function placeOrder(cart: Cart, repo: OrderRepo): Promise<Order> {
  const order = Order.fromCart(cart, Order.totalOf(cart));
  await repo.add(order);
  return order;
}
EOF

cat > "$OUTPUT_DIR/src/models/cart.ts" <<'EOF'
export interface CartItem {
  sku: string;
  unitPrice: number;
  quantity: number;
}

export interface Cart {
  customerId: string;
  items: CartItem[];
}
EOF

cat > "$OUTPUT_DIR/src/models/order.ts" <<'EOF'
import { db } from "../infrastructure/db";
import type { Cart, CartItem } from "./cart";

export interface OrderRepo {
  get(id: string): Promise<Order | null>;
  add(order: Order): Promise<void>;
}

export class Order {
  id: string = crypto.randomUUID();
  items: CartItem[];
  total: number;
  customerEmail: string | null = null;

  constructor(items: CartItem[], total: number) {
    this.items = items;
    this.total = total;
  }

  static totalOf(cart: Cart): number {
    return cart.items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
  }

  static fromCart(cart: Cart, total: number): Order {
    return new Order(cart.items, total);
  }

  static async find(id: string): Promise<Order | null> {
    return db.orders.find(id);
  }
}
EOF

cat > "$OUTPUT_DIR/src/models/customer/customer.ts" <<'EOF'
export type CustomerTier = "regular" | "gold";

export interface Customer {
  id: string;
  tier: CustomerTier;
}
EOF

cat > "$OUTPUT_DIR/src/services/pricing-service.ts" <<'EOF'
import type { Customer, CustomerTier } from "../models/customer/customer";
import type { Cart, CartItem } from "../models/cart";

const GOLD_DISCOUNT = 0.9;

function itemsTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
}

export function discounted(cart: Cart, tier: CustomerTier): number {
  const total = itemsTotal(cart.items);
  if (tier === "gold") {
    return total * GOLD_DISCOUNT;
  }
  return total;
}
EOF

cat > "$OUTPUT_DIR/src/infrastructure/db.ts" <<'EOF'
import type { Customer, CustomerTier } from "../models/customer/customer";
import type { Order } from "../models/order";

interface StoredOrder {
  id: string;
  items: unknown[];
  total: number;
}

const storedOrders: StoredOrder[] = [];

export const db = {
  customers: {
    async find(id: string): Promise<Customer & { tier: CustomerTier }> {
      return { id, tier: "gold" };
    },
  },
  orders: {
    async find(id: string): Promise<Order | null> {
      const row = storedOrders.find((stored) => stored.id === id);
      return row ? (row as unknown as Order) : null;
    },
    async insert(order: Order): Promise<void> {
      storedOrders.push(order as unknown as StoredOrder);
    },
  },
};
EOF

cat > "$OUTPUT_DIR/src/infrastructure/order-repo.ts" <<'EOF'
import type { Order, OrderRepo } from "../models/order";
import { db } from "./db";

export const orderRepo: OrderRepo = {
  async get(id): Promise<Order | null> {
    return db.orders.find(id);
  },
  async add(order): Promise<void> {
    await db.orders.insert(order);
  },
};
EOF

cat > "$OUTPUT_DIR/src/utils/helpers.ts" <<'EOF'
export function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export function slugify(text: string): string {
  return text.toLowerCase().replace(/\s+/g, "-");
}

export async function retry<T>(fn: () => Promise<T>): Promise<T> {
  return fn();
}
EOF

echo "fixture: $OUTPUT_DIR"
