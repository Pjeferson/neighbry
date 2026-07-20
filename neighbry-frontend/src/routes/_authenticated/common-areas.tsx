import { createFileRoute } from "@tanstack/react-router";
import { CommonAreaPage } from "@/features/common-area/CommonAreaPage";

export const Route = createFileRoute("/_authenticated/common-areas")({
  component: CommonAreaPage,
});
